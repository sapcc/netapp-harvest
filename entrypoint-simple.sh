#!/bin/bash
set -e

NETAPP_HOME=${NETAPP_HOME:-/opt/netapp-harvest}
NETAPP_FILERS_YAML=${NETAPP_HOME}/config/netapp-filers.yaml
NETAPP_HARVEST_CONF=${NETAPP_HOME}/config/netapp-harvest.conf
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
  echo "username = $username"
  echo "password = $password"
  echo "group = $FILER_GROUP"
}


if [ ! -f "$NETAPP_FILERS_YAML" ]; then 
  echo "file $NETAPP_FILERS_YAML does not exist"
  exit 1
fi

i=0
while [ $(read_name $i) != "null" ]; do
  write_config $i >> $NETAPP_HARVEST_CONF
  echo >> $NETAPP_HARVEST_CONF
  i=$((i+1))
done

# netapp manager start 
${NETAPP_HOME}/netapp-manager -start \
    -confdir ${NETAPP_HOME}/config \
    -logdir ${NETAPP_HOME}/log
    #-group ${FILER_GROUP} \

# check status every 10 seconds
while true; do
    if ls ${NETAPP_HOME}/log/*.log 1> /dev/null 2>&1; then
        tail -f ${NETAPP_HOME}/log/*.log
    else
        echo "sleep 10 seconds"
        sleep 10
    fi
done
