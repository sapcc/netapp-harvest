#!/bin/bash
set -e

NETAPP_HOME=/opt/netapp-harvest
#FILER_GROUP=

#===============================================================================

# netapp manager start 
${NETAPP_HOME}/netapp-manager -start \
    -confdir ${NETAPP_HOME} \
    -logdir ${NETAPP_HOME}/log
    #-group ${FILER_GROUP} \

# check status every 10 seconds
sleep 10 && tail -f ${NETAPP_HOME}/log/*.log
