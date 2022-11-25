#!/bin/bash

ceph_pool_name=$1
ceph_image_name=$2
root_dir=/mnt/harbor-offline-installer
default_interface=eth0

func_check_ip_count() {
	local ip_count
	ip_count=$(ip addr | grep inet | grep -c $default_interface)
	return "$ip_count"
}

func_check_harbor() {
	local harbor_containers_count
	harbor_containers_count=$(docker ps | grep -c harbor)
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
		client_id=$(rbd status "$ceph_pool_name"/"$ceph_image_name" | grep "watcher=" | awk -F "watcher=" '{print $2}' | awk '{print $1}')
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

orgin_ip_count=$(func_check_ip_count)
while true; do
	if [ "$(func_check_ip_count)" -gt "$orgin_ip_count" ]; then
		func_start
	fi

	if [ "$(func_check_ip_count)" -lt "$orgin_ip_count" ]; then
		func_clean
	fi
	sleep 1
done
