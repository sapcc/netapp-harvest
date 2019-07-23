#!/bin/bash
set -e

NETAPP_HOME=${NETAPP_HOME:-/opt/netapp-harvest}
NETBOX_FILERS_FILE=${NETAPP_HOME}/netbox_filers.yaml
NETAPP_FILERS_CONF=${NETAPP_HOME}/netapp-harvest.conf
NETAPP_USERNAME=${NETAPP_USERNAME:-admin}
NETAPP_PASSWORD=${NETAPP_PASSWORD:-netapp123}
YQ_CMD=${NETAPP_HOME/yq}

#===============================================================================

function read_name() {
  local name
  name=`echo "$1.name" | xargs $YQ_CMD r $NETBOX_FILERS_FILE`
  echo "$name"
}

function read_host() {
  local host
  host=`echo "$1.host" | xargs $YQ_CMD r $NETBOX_FILERS_FILE`
  echo "$host"
}

function set_filer_group() {
    if [[ $1 =~ bb[0-9]+$ ]]; then
        FILER_GROUP="vpod"
    fi
}
function write_config() {
  if [ "x$1" == "x" ]; then
    exit -1
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

i=0
while [ $(read_name $i) != "null" ]; do
  write_config $i >> $NETAPP_FILERS_CONF
  echo >> $NETAPP_FILERS_CONF
  i=$((i+1))
done

# netapp manager start 
${NETAPP_HOME}/netapp-manager -start \
    -confdir ${NETAPP_HOME} \
    -logdir ${NETAPP_HOME}/log
    #-group ${FILER_GROUP} \

# check status every 10 seconds
sleep 10 && tail -f ${NETAPP_HOME}/log/*.log
