#!/bin/bash

set -xe

if [ -n "$CEPH_POOL_NAME" ]; then
	echo "env CEPH_POOL_NAME not defined"
	return
fi
if [ -n "$CEPH_IMAGE_NAME" ]; then
	echo "env CEPH_IMAGE_NAME not defined"
	return
fi
if [ -n "$CEPH_MON_HOST" ]; then
	echo "env CEPH_MON_HOST not defined"
	return
fi
if [ -n "$CEPH_USER" ]; then
	echo "env CEPH_USER not defined"
	return
fi
if [ -n "$CEPH_USER_KEY" ]; then
	echo "env CEPH_USER_KEY not defined"
	return
fi

ceph_keyring_file="/etc/ceph/ceph.${CEPH_USER}.keyring"
ceph_rbd_image_spec="${CEPH_POOL_NAME}/${CEPH_IMAGE_NAME}"
root_dir="/mnt/harbor-offline-installer"

echo -e "[global]\nmon_host = ${CEPH_MON_HOST}" >/etc/ceph/ceph.conf
echo -e "[client.${CEPH_USER}]\n\tkey = ${CEPH_USER_KEY}" >"$ceph_keyring_file"
echo "${ceph_rbd_image_spec} id=${CEPH_USER},keyring=${ceph_keyring_file}" >/etc/ceph/rbdmap

func_check_ip_count() {
	local ip_count
	ip_count=$(hostname -I | sed 's/ /\n/g' | grep -v '^$')
	return "$ip_count"
}

func_check_harbor() {
	local harbor_containers_count
	harbor_containers_count=$(ps -ef | grep -c harbor)
	if [ "$harbor_containers_count" -gt 0 ]; then
		echo "harbor is running..."
		return 0
	else
		echo "harbor is not running!"
		return 1
	fi
}

func_start() {
	local client_id
	if ! rbdmap map; then
		# watcher=192.168.55.2:0/2900899764 client.14844 cookie=139644428642944
		client_id=$(rbd status "${ceph_rbd_image_spec}" | grep "watcher=" | awk -F "watcher=" '{print $2}' | awk '{print $1}')
		ceph osd blacklist add "$client_id"
	fi

	cd $root_dir || return
	if [ "$(func_check_harbor)" ]; then
		docker-compose down -v
	fi
	docker-compose up -d

	if [ -n "$client_id" ]; then
		ceph osd blacklist rm "$client_id"
	fi
}

func_clean() {
	cd $root_dir || return
	if [ "$(func_check_harbor)" ]; then
		docker-compose down -v
	fi

	rbdmap unmap
}

origin_ip_count=$(func_check_ip_count)
while true; do
	if [ "$(func_check_ip_count)" -gt "$origin_ip_count" ]; then
		func_start
	fi

	if [ "$(func_check_ip_count)" -lt "$origin_ip_count" ]; then
		func_clean
	fi
	sleep 1
done
