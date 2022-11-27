ARG RUNIT_VER=2.1.2

FROM ubuntu:22.04 as ubuntu

# install runit
RUN wget -P /tmp https://ftp.debian.org/debian/pool/main/r/runit/runit_${RUNIT_VER}.orig.tar.gz && \
    gunzip /tmp/runit_${RUNIT_VER}.orig.tar.gz && \
    tar -zxpf /tmp/runit_${RUNIT_VER}.orig.tar -C /tmp && \
    cd /tmp/admin/runit-${RUNIT_VER}/ && \
    package/install






COPY --from=ubuntu  /tmp/admin/runit-${RUNIT_VER}/command/* /usr/local/bin/

CMD ["start_runit"]
