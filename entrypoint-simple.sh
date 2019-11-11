#!/bin/bash
set -e

NETAPP_HOME=${NETAPP_HOME:-/opt/netapp-harvest}
NETAPP_FILERS_YAML=${NETAPP_HOME}/config/netapp-filers.yaml
NETAPP_HARVEST_CONF_TMPL=${NETAPP_HOME}/config/netapp-harvest.conf
NETAPP_HARVEST_CONF=${NETAPP_HOME}/netapp-harvest.conf
NETAPP_USERNAME=${NETAPP_USERNAME:-admin}
NETAPP_PASSWORD=${NETAPP_PASSWORD:-netapp123}

#===============================================================================

function read_name() {
    local name
    name=`echo "$1.name" | xargs yq r $NETAPP_FILERS_YAML`
    echo "$name"
}

function read_host() {
    local host
    host=`echo "$1.host" | xargs yq r $NETAPP_FILERS_YAML`
    echo "$host"
}

function set_filer_group() {
    if [[ $1 =~ bb[0-9]+$ ]]; then
        FILER_GROUP="vpod"
    fi
}
function write_config() {
    if [ "x$1" == "x" ]; then
        return 1
    fi
    local name
    local host
    name=$(read_name $1)
    host=$(read_host $1)
    set_filer_group $name
    echo "[$name]"
    echo "hostname = $host"
    echo "username = $NETAPP_USERNAME"
    echo "password = $NETAPP_PASSWORD"
    echo "group = $FILER_GROUP"
}


if [ ! -f "$NETAPP_FILERS_YAML" ]; then 
    echo "file $NETAPP_FILERS_YAML does not exist"
    exit 1
fi

cp $NETAPP_HARVEST_CONF_TMPL $NETAPP_HARVEST_CONF
checksum=

# check status every 60 seconds
# check netapp-filers.yaml
while true; do
    newchecksum=$(cat $NETAPP_FILERS_YAML | md5sum | cut -d ' ' -f 1)
    if [ "$checksum" != "$newchecksum" ]; then
        checksum=$newchecksum
        ${NETAPP_HOME}/netapp-manager -stop \
            -confdir ${NETAPP_HOME} \
            -logdir ${NETAPP_HOME}/log

        i=0
        cp $NETAPP_HARVEST_CONF_TMPL $NETAPP_HARVEST_CONF
        while [ $(read_name $i) != "null" ]; do
            write_config $i >> $NETAPP_HARVEST_CONF
            echo >> $NETAPP_HARVEST_CONF
            i=$((i+1))
        done

        ${NETAPP_HOME}/netapp-manager -start \
            -confdir ${NETAPP_HOME} \
            -logdir ${NETAPP_HOME}/log
    fi


    # if ls ${NETAPP_HOME}/log/*.log 1> /dev/null 2>&1; then
    #     tail -f ${NETAPP_HOME}/log/*.log
    # fi
    # ${NETAPP_HOME}/netapp-manager -status \
    #     -confdir ${NETAPP_HOME}
    # echo "sleep 60 seconds"
    sleep 60
done
