#!/bin/bash
set -e
set -u

NETAPP_HOME=${NETAPP_HOME:-/opt/netapp-harvest}
NETAPP_FILERS_YAML=${NETAPP_HOME}/config/netapp-filers.yaml
NETAPP_HARVEST_CONF_TMPL=${NETAPP_HOME}/config/netapp-harvest.conf
NETAPP_HARVEST_CONF=${NETAPP_HOME}/netapp-harvest.conf
NETAPP_USERNAME=${NETAPP_USERNAME:-admin}
NETAPP_PASSWORD=${NETAPP_PASSWORD:-netapp123}
REPLICA=${HOSTNAME##*-}

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
    elif [[ $1 =~ cp[0-9]+$ ]]; then
        FILER_GROUP="control-plane"
    elif [[ $1 =~ md[0-9]+$ ]]; then
        FILER_GROUP="manila"
    elif [[ $1 =~ bm[0-9]+$ ]]; then
        FILER_GROUP="bare-metal"
    else
        FILER_GROUP="unknown"
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

function check_filer_with_backoff {
    # find filer file with exponetial backoff timeout 1, 2, 4, 8, ..., 256, 300, 300, ...
    # returns checksum of the found file
    local timeout_max=300
    local timeout=${TIMEOUT-1}
    local attempt=0

    while true;
    do
        if [ -f "$NETAPP_FILERS_YAML" ]; then 
            echo $(cat $NETAPP_FILERS_YAML | md5sum | cut -d ' ' -f 1)
            break
        else
            >&2 echo "File $NETAPP_FILERS_YAML not found. Retrying in $timeout.."
        fi

        sleep $timeout
        attempt=$(( attempt + 1 ))
        timeout=$(( timeout * 2 ))
        if [ "$timeout" -gt "$timeout_max" ]; then
            timeout=$timeout_max
        fi
    done
}

#===============================================================================

# check netapp-filers.yaml every 300 seconds
checksum=

while true; do
    restart=0
    newchecksum=$(check_filer_with_backoff)

    if [ "$checksum" != "$newchecksum" ]; then
        # restart if checksum is different
        restart=1
        checksum=$newchecksum

        # read $NETAPP_FILERS_YAML and re-generate $NETAPP_HARVEST_CONF
        echo "generating harvest config from filers in $NETAPP_FILERS_YAML on replica $REPLICA"
        cp $NETAPP_HARVEST_CONF_TMPL $NETAPP_HARVEST_CONF

        i=0
        while [ $(read_name $i) != "null" ]; do
            if (( i % REPLICAS == REPLICA )); then
                echo "add filer $(read_name $i)"
                write_config $i >> $NETAPP_HARVEST_CONF
                echo >> $NETAPP_HARVEST_CONF
            fi
            i=$(( i + 1 ))
        done
    else
        # check netapp manager status: restart when no worker is running
        running_workers=$(${NETAPP_HOME}/netapp-manager -status -confdir ${NETAPP_HOME} | grep '^\[RUNNING\]' | wc -l)
        if [ "$running_workers" -eq "0" ]; then
            restart=1
        fi
    fi

    if [ "$restart" -gt "0" ]; then
        ${NETAPP_HOME}/netapp-manager -stop -confdir ${NETAPP_HOME} -logdir ${NETAPP_HOME}/log
        ${NETAPP_HOME}/netapp-manager -start -confdir ${NETAPP_HOME} -logdir ${NETAPP_HOME}/log
    fi

    # if ls ${NETAPP_HOME}/log/*.log 1> /dev/null 2>&1; then
    #     tail -f ${NETAPP_HOME}/log/*.log
    # fi
    # echo "sleep 300 seconds"
    sleep 300
done

# vim: sw=4
