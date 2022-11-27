#!/bin/sh

VIP=$1

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

if ip addr | grep -q $VIP; then
    if curl --silent --max-time 3 http://${VIP}:8080/api/v2.0/health | grep -q unhealthy; then
        errorExit "Error GET http://${VIP}:8080/api/v2.0/health"
    fi
fi