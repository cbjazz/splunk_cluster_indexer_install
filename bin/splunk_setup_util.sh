#!/bin/sh
execute_dir=`dirname $0`
execute_file=`basename $0`

option=$1

if [ -z "${option}" ]; then
        echo "USAGE: ${execute_file} [ouput|register]"
        exit 1
fi

source ./common.sh

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

IFS=',' read -r -a INDEXER_DIR_ARR <<< "${__property_indexer_dir}"
IFS=',' read -r -a MANAGEMENT_PORT_ARR <<< "${__property_management_port}"
IFS=',' read -r -a APPSERVER_PORT_ARR <<< "${__property_appserver_port}"
IFS=',' read -r -a KV_STORE_PORT_ARR <<< "${__property_kv_store_port}"
IFS=',' read -r -a LISTEN_PORT_ARR <<< "${__property_listen_port}"
IFS=',' read -r -a REPLICATION_PORT_ARR <<< "${__property_replication_port}"

master_host=`cat ${execute_dir}/../conf/hosts.conf | grep "MASTER" | awk -F"=" '{print $2}'`
indexer_hosts=`cat ${execute_dir}/../conf/hosts.conf | grep "INDEXER" | awk -F"=" '{print $2}'`
IFS=',' read -r -a indexer_host_arr <<< "${indexer_hosts}"
host_len=${#indexer_host_arr[@]}
seg_len=${#INDEXER_DIR_ARR[@]}

gen_reg_cluster() {
echo "./splunk edit shcluster-config -mgmt_uri ${master_host}:${MASTER_PORT} -mode searchhead -secret ${CLUSTER_SECRET}"
}

gen_output() {
idx_server=""
for (( i=0; i < $host_len; i++));
do
	indexer_host=${indexer_host_arr[$i]}
	for (( j=0; j < $seg_len; j++));
	do
        	listen_port="${LISTEN_PORT_ARR[$j]}"
		if [ ${i} -eq 0 -a ${j} -eq 0 ]; then
			idx_server=${indexer_host}:${listen_port}	
		else
			idx_server=${idx_server},${indexer_host}:${listen_port}
		fi
	done
done
echo "[indexAndForward]
index=false

[tcpout]
defaultGroup = default-autolb-group
forwardedindex.filter.disable=true
indexAndForward = false

[tcpout:default-autolb-group]
server=${idx_server}"
}

if [ "output" == "${option}" ]; then
	gen_output
fi

if [ "register" == "${option}" ]; then
	gen_reg_cluster
fi
