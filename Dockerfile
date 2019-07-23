FROM centos:latest as build0

ENV NETAPP_HARVEST_HOME=/opt/netapp-harvest
ENV NETAPP_HARVEST_VERSION=1.4.1-1
ENV NM_SDK_VERSION=9.4
RUN yum -y update && yum install -y unzip
RUN mkdir -p ${NETAPP_HARVEST_HOME}/lib
RUN mkdir -p ${NETAPP_HARVEST_HOME}/log

COPY assets/netapp-harvest-${NETAPP_HARVEST_VERSION}.noarch.rpm /
RUN yum -y install netapp-harvest-${NETAPP_HARVEST_VERSION}.noarch.rpm \
    && chmod +x ${NETAPP_HARVEST_HOME}/netapp-manager \
    && chmod +x ${NETAPP_HARVEST_HOME}/netapp-worker

COPY assets/netapp-manageability-sdk-${NM_SDK_VERSION}.zip /
RUN unzip -j netapp-manageability-sdk-${NM_SDK_VERSION}.zip netapp-manageability-sdk-${NM_SDK_VERSION}/lib/perl/NetApp/* -d ${NETAPP_HARVEST_HOME}/lib 

#---

FROM centos:latest
ENV NETAPP_HARVEST_HOME=/opt/netapp-harvest

WORKDIR ${NETAPP_HARVEST_HOME}

RUN yum -y update \
 && yum -y install \
         less \
         epel-release \
         perl \
         perl-JSON \
         perl-libwww-perl \
         perl-XML-Parser \
         perl-Net-SSLeay \
         perl-Time-HiRes \
         perl-LWP-Protocol-https \
         perl-IO-Socket-SSL \
         perl-Excel-Writer-XLSX \
 && yum clean all 

COPY --from=build0 ${NETAPP_HARVEST_HOME}/ ${NETAPP_HARVEST_HOME}/
COPY assets/yq_linux_amd64 ${NETAPP_HARVEST_HOME}/yq
COPY netapp-harvest.conf.tmpl ${NETAPP_HARVEST_HOME}/netapp-harvest.conf
COPY entrypoint-simple.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh ${NETAPP_HARVEST_HOME}/yq

EXPOSE 2003 2004

ENTRYPOINT [ "/entrypoint.sh" ]
