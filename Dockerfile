FROM ubuntu:18.04

ARG CEPH_VERSION=nautilus

RUN apt-get update && \
    apt-get install -y  --no-install-recommends \
    wget \
    ca-certificates \
    gnupg2 \
    runit \
    gettext-base

RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add - && \
    OS_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | awk -F= '{print $2}') && \
    echo "deb http://download.ceph.com/debian-$CEPH_VERSION/ $OS_CODENAME main" | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list && \
    apt-get update && \
    CEPH_COMMON_VERSION=$(apt-cache madison ceph-common | grep "download.ceph.com/debian-$CEPH_VERSION" | awk '{print $3}') && \
    apt-get install -y  --no-install-recommends ceph-common=$CEPH_COMMON_VERSION && \
    dpkg -s ceph-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY /etc/. /etc/
COPY harbor_failover /usr/bin/

CMD ["runsvdir" , "-P", "/etc/service/"]
