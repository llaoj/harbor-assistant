#!/bin/bash

set -e

if [ -n "$KEEPALIVED_VIP" ]; then
	echo "env KEEPALIVED_VIP not defined"
	return
fi
if [ -n "$KEEPALIVED_ROLE" ]; then
	echo "env KEEPALIVED_ROLE not defined"
	return
fi

KEEPALIVED_CONF_TEMPLATE="./keepalived-${KEEPALIVED_ROLE}.template"
KEEPALIVED_CONF_FILE="/etc/keepalived/keepalived.conf"
envsubst < ${KEEPALIVED_CONF_TEMPLATE} > ${KEEPALIVED_CONF_FILE}
echo "Success generate ${KEEPALIVED_CONF_FILE}"