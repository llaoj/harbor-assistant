FROM ubuntu:18.04

ARG CEPH_VERSION=nautilus

RUN apt-get update && \
    apt-get install -y  --no-install-recommends \
    wget \
    ca-certificates \
    gnupg2 \
    runit \
    gettext-base \
    kmod

RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add - && \
    OS_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | awk -F= '{print $2}') && \
    echo "deb http://download.ceph.com/debian-$CEPH_VERSION/ $OS_CODENAME main" | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list && \
    apt-get update && \
    CEPH_COMMON_VERSION=$(apt-cache madison ceph-common | grep "download.ceph.com/debian-$CEPH_VERSION" | awk '{print $3}') && \
    apt-get install -y  --no-install-recommends ceph-common=$CEPH_COMMON_VERSION && \
    dpkg -s ceph-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q -O /usr/bin/docker-compose https://github.com/docker/compose/releases/download/v2.13.0/docker-compose-linux-x86_64 && \
    chmod +x /usr/bin/docker-compose

COPY /etc/. /etc/
COPY  harborctl /usr/bin/
COPY bootstrap.sh /

RUN chmod +x /usr/bin/rbdmap /usr/bin/harborctl /bootstrap.sh && \
    chmod -R +x /etc/service/

CMD ["/bootstrap.sh"]
