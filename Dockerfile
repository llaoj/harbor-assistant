FROM debian:buster

ARG CEPH_VERSION=nautilus

# RUN echo "deb http://download.ceph.com/debian-$CEPH_VERSION/ xenial main" | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list && \
#     && apt-get update && apt-get install -y  --no-install-recommends --force-yes ceph-common \
#     && dpkg -s $PACKAGES \
#     && apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
RUN apt-get update && \
    apt-get install -y  --no-install-recommends \
    wget \
    ca-certificates \
    gnupg2 \
    procps \
    runit

RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add - && \
    OS_CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | awk -F= '{print $2}') && \
    echo "deb http://download.ceph.com/debian-$CEPH_VERSION/ $OS_CODENAME main" | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list && \
    apt-get update && \
    apt-cache madison ceph-common && \
    apt-get install -y  --no-install-recommends \
    ceph-common=14 && \
    # ceph-common amd64 12.2.11+dfsg1-2.1+b1
    ceph -v && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["runsvdir" , "-P", "/etc/service/"]
