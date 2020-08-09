#!/bin/sh

execute_dir=`dirname $0`
execute_file=`basename $0`

SETUP_PASSWORD=$1

source ${execute_dir}/common.sh

logging ECHO "####################################"
logging ECHO "# 0. Prepare Environment           #"
logging ECHO "####################################"
load_properties

CLUSTER_NAME="${__property_cluster_name}"
CLUSTER_SECRET="${__property_cluster_secret}"
LICENSE_SERVER="${__property_license_server}"
SERVER_NAME_PREFIX="${__property_server_name_prefix}"
MASTER_DIR="${__property_master_dir}"
REPLICATION_FACTOR="${__property_replication_factor}"
SEARCH_FACTOR="${__property_search_factor}"

MASTER_MANAGEMENT_PORT="${__property_master_management_port}"
MASTER_APPSERVER_PORTS="${__property_master_appserver_ports}"
MASTER_KV_STORE_PORT="${__property_master_kv_store_port}"
MASTER_WEB_PORT="${__property_master_web_port}"

logging INFO "CLUSTER_NAME=${__property_cluster_name}"
logging INFO "CLUSTER_SECRET=${__property_cluster_secret}"
logging INFO "LICENSE_SERVER=${__property_license_server}"
logging INFO "SERVER_NAME_PREFIX=${__property_server_name_prefix}"
logging INFO "MASTER_DIR=${__property_master_dir}"
logging INFO "REPLICATION_FACTOR=${__property_replication_factor}"
logging INFO "SEARCH_FACTOR=${__property_search_factor}"
logging INFO "MASTER_WEB_PORT=${__property_master_web_port}"
logging INFO "MASTER_MANAGEMENT_PORT=${__property_master_management_port}"
logging INFO "MASTER_APPSERVER_PORTS=${__property_master_appserver_ports}"
logging INFO "MASTER_KV_STORE_PORT=${__property_master_kv_store_port}"

# Splunk Install uncomporess tar
logging ECHO "####################################"
logging ECHO "# 1. Install Splunk(MASTER)        #"
logging ECHO "####################################"
splunk_bin=`ls ${execute_dir}/../resources/splunk*.tgz`
if [ -z ${splunk_bin} ]; then
	logging ERROR "Splunk install file does not exist!!"
	exit 1
fi

# TODO: We may run it with 'root' user.
# Check install directory 
dir_list=`ls $MASTER_DIR`

no_access=`echo $dir_list | grep "cannot access" | wc -l`

if [ "1" == "${no_access}" ]; then
	logging ERROR "Cannot access $MASTER_DIR"
	exit 1;
fi

if [ -z ${dir_list} ]; then
	logging WARN "$MASTER_DIR does not exisit...."
	logging ECHO "Create new $MASTER_DIR directory"
	mkdir -p $MASTER_DIR
else 
	# MASTER DIR directory should be empty.
	files_count=`ls $MASTER_DIR/`
	if [ "0" != "$files_count" ]; then
		logging ERROR "$MASTER_DIR is not empty"
		exit 1;
	fi
fi
# uncompress splunk compressed file
tar xvfz $splunk_bin -C $MASTER_DIR > /dev/null
# TODO: Add to success check. 


logging ECHO "####################################"
logging ECHO "# 2. Init Splunk(MASTER)           #"
logging ECHO "####################################"
${execute_dir}/autoinstall.sh $SETUP_PASSWORD $MASTER_DIR/splunk/bin/splunk start --accept-license
error_check=`$MASTER_DIR/splunk/bin/splunk status`
if [ "splunkd is not running." == "$error_check" ]; then
	logging ERROR "Splunk Restart failed. Check the splunk log."
	exit 1;
fi

logging ECHO "####################################"
logging ECHO "# 3. Init Splunk(MASTER)           #"
logging ECHO "####################################"
hostname=`hostname`

# Set servername
$MASTER_DIR/splunk/bin/splunk set servername ${SERVER_NAME_PREFIX}_${hostname}_master -auth admin:${SETUP_PASSWORD}
# TODO: Add to sucess check. 

# Set hostname
hostname=`hostname`
$MASTER_DIR/splunk/bin/splunk set default-hostname ${hostname}_master -auth admin:${SETUP_PASSWORD}
# TODO: Add to sucess check. 

# Register to license server
$MASTER_DIR/splunk/bin/splunk edit licenser-localslave -master_uri https://${LICENSE_SERVER} -auth admin:${SETUP_PASSWORD}
# TODO: Add to sucess check. 

# Set Cluster master
$MASTER_DIR/splunk/bin/splunk edit cluster-config -mode master -replication_factor ${REPLICATION_FACTOR} -search_factor ${SEARCH_FACTOR} -secret ${CLUSTER_SECRET} -auth admin:${SETUP_PASSWORD}
# TODO: Add to sucess check. 

# Set Cluster name
$MASTER_DIR/splunk/bin/splunk edit cluster-config -cluster_label "${CLUSTER_NAME}" -authadmin:${SETUP_PASSWORD}
# TODO: Add to sucess check. 

# Set ports 
if [ "8090" != "${MASTER_MANAGEMENT_PORT}" ]; then
	logging ECHO "$MASTER_DIR/splunk/bin/splunk set splunkd-port ${MASTER_MANAGEMENT_PORT}"
        $MASTER_DIR/splunk/bin/splunk set splunkd-port ${MASTER_MANAGEMENT_PORT} -auth admin:${SETUP_PASSWORD}
fi
	
if [ "8065" != "${MASTER_APPSERVER_PORTS}" ]; then
	logging ECHO "$MASTER_DIR/splunk/bin/splunk set appserver-ports ${MASTER_APPSERVER_PORTS}"
        $MASTER_DIR/splunk/bin/splunk set appserver-ports ${MASTER_APPSERVER_PORTS} -auth admin:${SETUP_PASSWORD}
fi

if [ "8191" != "${MASTER_KV_STORE_PORT}" ]; then
        logging ECHO "$MASTER_DIR/splunk/bin/splunk set kvstore-port ${MASTER_KV_STORE_PORT}"
        $MASTER_DIR/splunk/bin/splunk set kvstore-port ${MASTER_KV_STORE_PORT} -auth admin:${SETUP_PASSWORD}
        # TODO: Add to sucess check. 
fi

if [ "8000" != "${MASTER_WEB_PORT}" ]; then
        logging ECHO "$MASTER_DIR/splunk/bin/splunk set web-port ${MASTER_WEB_PORT}"
        $MASTER_DIR/splunk/bin/splunk set web-port ${MASTER_WEB_PORT} -auth admin:${SETUP_PASSWORD}
        # TODO: Add to sucess check. 
fi

logging ECHO "####################################"
logging ECHO "# 3. Restart Splunk(MASTER)        #"
logging ECHO "####################################"
result=`$MASTER_DIR/splunk/bin/splunk restart`
error_check=`$MASTER_DIR/splunk/bin/splunk status`
if [ "splunkd is not running." == "$error_check" ]; then
	logging ERROR "Splunk Restart failed. Check the splunk log."
	logging INFO "${result}"
	exit 1;
fi

echo "Setup Succefully Completed"
