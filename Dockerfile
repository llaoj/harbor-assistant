ARG RUNIT_VER=2.1.2
# ARG CEPH_VERSION luminous

FROM ubuntu:22.04 as ubuntu

# install runit
RUN wget -P /tmp https://ftp.debian.org/debian/pool/main/r/runit/runit_${RUNIT_VER}.orig.tar.gz && \
    gunzip /tmp/runit_${RUNIT_VER}.orig.tar.gz && \
    tar -zxpf /tmp/runit_${RUNIT_VER}.orig.tar -C /tmp && \
    cd /tmp/admin/runit-${RUNIT_VER}/ && \
    package/install && \
    ls -la /tmp/admin/runit-${RUNIT_VER}/command && \
    cp /tmp/admin/runit-${RUNIT_VER}/command/* /usr/local/bin/ && \
    rm -rf /tmp/*

# RUN echo "deb http://download.ceph.com/debian-$CEPH_VERSION/ xenial main" | tee /etc/apt/sources.list.d/ceph-$CEPH_VERSION.list && \
#     && apt-get update && apt-get install -y  --no-install-recommends --force-yes ceph-common \
#     && dpkg -s $PACKAGES \
#     && apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
RUN apt-get update && \
    apt-cache search ceph-common

CMD ["start_runit"]
