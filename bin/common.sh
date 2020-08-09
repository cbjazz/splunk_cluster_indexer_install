#!/bin/sh
execute_dir=`dirname $0`
execute_file=`basename $0`

load_properties() {
    local aline= var= value=
        while read aline; do
            aline=${aline//\#*/}
            [[ -z $aline ]] && continue
            IFS='=' read var value <<<$aline
            [[ -z $var ]] && continue
            eval __property_$var=\"$value\"
        done < ${execute_dir}/../conf/splunk_install.conf
}

get_prop() {
    local var=$1 key=$2
    eval $var=\"\$__property_$key\"
}
LOGFILE=${execute_dir}/../log/splunk_install.log
logging() {
    echo `date` ${1} ${2} >> ${LOGFILE}
    if [ "ECHO" == ${1} ]; then
	echo ${2}
    fi
    
    if [ "ERROR" == ${1} ]; then
	echo ${2}
    fi
}
