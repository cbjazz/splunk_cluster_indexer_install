#!/bin/sh
execute_dir=`dirname $0`
execute_file=`basename $0`

SETUP_PASSWORD=$1
MASTER_HOST=$2
INDEX_HOST=$3

source ./common.sh

logging ECHO "####################################"
logging ECHO "# 0. Prepare Environment           #"
logging ECHO "####################################"

load_properties

CLUSTER_NAME="${__property_cluster_name}"
CLUSTER_SECRET="${__property_cluster_secret}"
LICENSE_SERVER="${__property_license_server}"
SERVER_NAME_PREFIX="${__property_server_name_prefix}"
SETUP_PASSWORD="${__property_setup_password}"
MASTER_DIR="${__property_master_dir}"
REPLICATION_FACTOR="${__property_replication_factor}"
SEARCH_FACTOR="${__property_search_factor}"
MASTER_PORT="${__property_master_management_port}"

logging INFO "CLUSTER_NAME=${__property_cluster_name}"
logging INFO "CLUSTER_SECRET=${__property_cluster_secret}"
logging INFO "LICENSE_SERVER=${__property_license_server}"
logging INFO "SERVER_NAME_PREFIX=${__property_server_name_prefix}"
logging INFO "INDEXER_DIR=${__property_indexer_dir}"
logging INFO "MANAGEMENT_PORT=${__property_management_port}"
logging INFO "APPSERVER_PORTS=${__property_appserver_port}"
logging INFO "KV_STORE_PORT=${__property_kv_store_port}"
logging INFO "LISTEN_PORT=${__property_listen_port}"
logging INFO "REPLICATION_PORT=${__property_replication_port}"
logging INFO "MASTER_HOST=${MASTER_HOST}"
logging INFO "MASTER_PORT=${__property_master_management_port}"

IFS=',' read -r -a INDEXER_DIR_ARR <<< "${__property_indexer_dir}"
IFS=',' read -r -a MANAGEMENT_PORT_ARR <<< "${__property_management_port}"
IFS=',' read -r -a APPSERVER_PORT_ARR <<< "${__property_appserver_port}"
IFS=',' read -r -a KV_STORE_PORT_ARR <<< "${__property_kv_store_port}"
IFS=',' read -r -a LISTEN_PORT_ARR <<< "${__property_listen_port}"
IFS=',' read -r -a REPLICATION_PORT_ARR <<< "${__property_replication_port}"

len=${#INDEXER_DIR_ARR[@]}
# Splunk Install uncomporess tar
logging ECHO "################################################"
logging ECHO "# 1. Send Splunk Install File to ${INDEX_HOST} #"
logging ECHO "################################################"
splunk_bin=`ls ${execute_dir}/../resources/splunk*.tgz`
if [ -z ${splunk_bin} ]; then
	logging ERROR "Splunk install file does not exist!!"
	exit 1
fi

# Copy Splunk Install file
scp ${splunk_bin} ${INDEX_HOST}:/home/splunk/

for (( i=0; i < $len; i++)); 
do
	INDEXER_DIR="${INDEXER_DIR_ARR[$i]}"
	MANAGEMENT_PORT="${MANAGEMENT_PORT_ARR[$i]}"
	APPSERVER_PORT="${APPSERVER_PORT_ARR[$i]}"
	KV_STORE_PORT="${KV_STORE_PORT_ARR[$i]}"
	LISTEN_PORT="${LISTEN_PORT_ARR[$i]}"
	REPLICATION_PORT="${REPLICATION_PORT_ARR[$i]}"

	# TODO: We may run it with 'root' user.
	# Check install directory 
	dir_list=`ssh ${INDEX_HOST} "ls $INDEXER_DIR"`
	if [ -z ${dir_list} ]; then
		logging WARN "$INDXER_DIR does not exisit...."
		logging ECHO "Create new $INDEXER_DIR directory"
		`ssh ${INDEX_HOST} "mkdir -p $INDEXER_DIR"`
	else 
		# INDEXER DIR directory should be empty.
		files_count=`ssh ${INDEX_HOST} "ls $INDEXER_DIR/"`
		if [ "0" != "$files_count" ]; then
			logging ERROR "$INDEXER_DIR is not empty"
			exit 1;
		fi
	fi

	# uncompress splunk compressed file
	splunk_bin=`basename "${splunk_bin}"`
	ssh ${INDEX_HOST} "tar xvfz $splunk_bin -C $INDEXER_DIR" > /dev/null
	# TODO: Add to success check. 

	logging ECHO "####################################"
	logging ECHO "# 2. Init Splunk(INDEXER_$i)       #"
	logging ECHO "####################################"
	${execute_dir}/autoinstall.sh $SETUP_PASSWORD ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk start --accept-license"
	error_check=`ssh ${INDEX_HOST} "$INDEXER_DIR/splunk/bin/splunk status"`
	if [ "splunkd is not running." == "$error_check" ]; then
		logging ERROR "Splunk Restart failed. Check the splunk log."
		exit 1;
	fi

	logging ECHO "####################################"
	logging ECHO "# 3. Init Splunk(INDEXER_$i)       #"
	logging ECHO "####################################"

	# Set servername
	hostname=`ssh ${INDEX_HOST} "hostname"`
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk set servername ${SERVER_NAME_PREFIX}_${hostname}_idx${i}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk set servername ${SERVER_NAME_PREFIX}_${hostname}_idx${i} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	# Set hostname
	hostname=`ssh ${INDEX_HOST} "hostname"`
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk set default-hostname ${hostname}_idx${i}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk set default-hostname ${hostname}_idx${i} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	# Register to license server
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk edit licenser-localslave -master_uri https://${LICENSE_SERVER}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk edit licenser-localslave -master_uri https://${LICENSE_SERVER} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	# Set Listening 
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk enable listen ${LISTEN_PORT}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk enable listen ${LISTEN_PORT} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 
	
	# Disable Web
	logging ECHO  "$INDEXER_DIR/splunk/bin/splunk disable webserver"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk disable webserver -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	# Set ports 
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk set splunkd-port ${MANAGEMENT_PORT}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk set splunkd-port ${MANAGEMENT_PORT} -auth 'admin:${SETUP_PASSWORD}'"
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk set appserver-ports ${APPSERVER_PORT}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk set appserver-ports ${APPSERVER_PORT} -auth 'admin:${SETUP_PASSWORD}'"
	logging ECHO "$INDEXER_DIR/splunk/bin/splunk set kvstore-port ${KV_STORE_PORT}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk set kvstore-port ${KV_STORE_PORT} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	# Set Cluster Slave
	logging ECHO  "$INDEXER_DIR/splunk/bin/splunk edit cluster-config -mode slave -master_uri https://${MASTER_HOST}:${MASTER_PORT} -secret ${CLUSTER_SECRET} -replication_port ${REPLICATION_PORT}"
	ssh $INDEX_HOST "$INDEXER_DIR/splunk/bin/splunk edit cluster-config -mode slave -master_uri https://${MASTER_HOST}:${MASTER_PORT} -secret ${CLUSTER_SECRET} -replication_port ${REPLICATION_PORT} -auth 'admin:${SETUP_PASSWORD}'"
	# TODO: Add to sucess check. 

	logging ECHO "####################################"
	logging ECHO "# 4. Restart Splunk(INDEXER_$i)    #"
	logging ECHO "####################################"
	result=`ssh ${INDEX_HOST} "$INDEXER_DIR/splunk/bin/splunk restart"`
	error_check=`ssh ${INDEX_HOST} "$INDEXER_DIR/splunk/bin/splunk status"`
	if [ "splunkd is not running." == "$error_check" ]; then
		logging ERROR "Splunk Restart failed. Check the splunk log."
		logging INFO "${result}"
		exit 1;
	fi

done
