#/bin/sh

execute_dir=`dirname $0`
execute_file=`basename $0`
SETUP_PASSWORD=$1
SETUP_OPTION=$2

if [ -z "${SETUP_PASSWORD}" ]; then
	echo "USAGE: ${execute_file} setup_password [ALL|MASTER|INDEXER]"
	exit 1
fi

if [ -z "${SETUP_OPTION}" ]; then
	echo "USAGE: ${execute_file} setup_password [ALL|MASTER|INDEXER]"
	exit 1
fi

if [ "ALL" == "${SETUP_OPTION}" ]; then
	master_host=`cat ${execute_dir}/../conf/hosts.conf | grep "MASTER" | awk -F"=" '{print $2}'`
	result=`${execute_dir}/splunk_install_master.sh ${SETUP_PASSWORD}`
	is_success=`echo "${result}" | grep "Setup Succefully Completed" | wc -l`
	if [ "1" != "${is_success}" ]; then
		exit 1;
	fi

	sleep 60

	indexer_hosts=`cat ${execute_dir}/../conf/hosts.conf | grep "INDEXER" | awk -F"=" '{print $2}'`
	IFS=',' read -r -a indexer_host_arr <<< "${indexer_hosts}"
	len=${#indexer_host_arr[@]}
	for (( i=0; i < $len; i++));
	do
		indexer_host=${indexer_host_arr[$i]}
		result=`${execute_dir}/splunk_install_idx.sh ${SETUP_PASSWORD} ${master_host} ${indexer_host}`
	done
fi

if [ "MASTER" == "${SETUP_OPTION}" ]; then
	master_host=`cat ${execute_dir}/../conf/hosts.conf | grep "MASTER" | awk -F"=" '{print $2}'`
	result=`${execute_dir}/splunk_install_master.sh ${SETUP_PASSWORD}`
	is_success=`echo "${result}" | grep "Setup Succefully Completed" | wc -l`
	if [ "1" != "${is_success}" ]; then
		exit 1;
	fi
fi


if [ "INDEXER" == "${SETUP_OPTION}" ]; then
	master_host=`cat ${execute_dir}/../conf/hosts.conf | grep "MASTER" | awk -F"=" '{print $2}'`
	indexer_hosts=`cat ${execute_dir}/../conf/hosts.conf | grep "INDEXER" | awk -F"=" '{print $2}'`
	IFS=',' read -r -a indexer_host_arr <<< "${indexer_hosts}"
	len=${#indexer_host_arr[@]}
	for (( i=0; i < $len; i++));
	do
		indexer_host=${indexer_host_arr[$i]}
		result=`${execute_dir}/splunk_install_idx.sh ${SETUP_PASSWORD} ${master_host} ${indexer_host}`
	done
fi
