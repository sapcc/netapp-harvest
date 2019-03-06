#!/bin/bash
set -e

NETAPP_HOME=/opt/netapp-harvest
NETAPP_CONFDIR=${NETAPP_HOME} 
NETAPP_LOGDIR=${NETAPP_HOME}/log
HARVEST_CONFIG=${NETAPP_HOME}/netapp-harvest.conf
HARVEST_CONFIG_TMP=${NETAPP_HOME}/netapp-harvest.conf.tmp
HARVEST_CONFIG_TEMPLATE=${NETAPP_HOME}/netapp-harvest.conf.template

ordinal=${HOSTNAME##*-}
if [ -n "$ordinal" ]; then 
  ln -s /etc/netapp/group-$ordinal ${NETAPP_HOME}/filers 
fi

run_netapp_manager () {
  _filers=$1
  _restart=$2
  _arrFilers=( $(echo "${_filers//,/ }") )
  cp ${HARVEST_CONFIG_TEMPLATE} ${HARVEST_CONFIG_TMP}
  for i in "${!_arrFilers[@]}"; do
    ### append filer to config ###
cat <<EOF >> ${HARVEST_CONFIG_TMP}

[filer-$i]
hostname    = ${_arrFilers[$i]}
group       = filers
EOF
    ##############################
  done
  cp ${HARVEST_CONFIG_TMP} ${HARVEST_CONFIG}
  
  ### run netapp manager ###
  if [ -z ${_restart} ]; then
    echo 'starting...'
    ${NETAPP_HOME}/netapp-manager -start -group filers -confdir ${NETAPP_HOME} -logdir ${NETAPP_HOME}/log
  else
    echo 'restarting...'
    ${NETAPP_HOME}/netapp-manager -restart -group filers -confdir ${NETAPP_HOME} -logdir ${NETAPP_HOME}/log
  fi
  ##########################
}


#### main programm ###


old_filers=`cat ${NETAPP_HOME}/filers`
run_netapp_manager ${old_filers}

while true; do
  sleep 10
  new_filers=`cat ${NETAPP_HOME}/filers`
  if [ "${new_filers}" != "${old_filers}" ]; then
    # restart workers
    run_netapp_manager ${new_filers} --restart
    old_filers=${new_filers}
  fi
done

exec "$@"
