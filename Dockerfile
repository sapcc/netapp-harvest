FROM centos:centos7.6.1810 as build0
ENV NETAPP_HARVEST_HOME=/opt/netapp-harvest
ENV NETAPP_HARVEST_VERSION=1.6-1
ENV NM_SDK_VERSION=9.4
RUN yum -y update && yum install -y \
    epel-release unzip perl perl-JSON \
    perl-libwww-perl perl-XML-Parser perl-Net-SSLeay \
    perl-Time-HiRes perl-LWP-Protocol-https perl-IO-Socket-SSL
RUN yum install -y perl-Excel-Writer-XLSX
RUN mkdir -p ${NETAPP_HARVEST_HOME}/lib
RUN mkdir -p ${NETAPP_HARVEST_HOME}/log

COPY assets/netapp-harvest-${NETAPP_HARVEST_VERSION}.noarch.rpm /
RUN yum -y install netapp-harvest-${NETAPP_HARVEST_VERSION}.noarch.rpm \
    && chmod +x ${NETAPP_HARVEST_HOME}/netapp-manager \
    && chmod +x ${NETAPP_HARVEST_HOME}/netapp-worker

COPY assets/netapp-manageability-sdk-${NM_SDK_VERSION}.zip /
RUN unzip -j netapp-manageability-sdk-${NM_SDK_VERSION}.zip netapp-manageability-sdk-${NM_SDK_VERSION}/lib/perl/NetApp/* -d ${NETAPP_HARVEST_HOME}/lib 

#---

FROM centos:centos7.6.1810
LABEL source_repository="https://github.com/sapcc/netapp-harvest"
ENV NETAPP_HARVEST_HOME=/opt/netapp-harvest
ENV LC_ALL=C

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
         perl-IO-Socket-SSL
RUN yum install -y perl-Excel-Writer-XLSX \
 && yum clean all 

COPY --from=build0 ${NETAPP_HARVEST_HOME}/ ${NETAPP_HARVEST_HOME}/
COPY assets/yq_linux_amd64 /usr/bin/yq
COPY entrypoint-simple.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/bin/yq

EXPOSE 2003 2004

ENTRYPOINT [ "/entrypoint.sh" ]
