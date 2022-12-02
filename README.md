## Why

部署两个Harbor实例来实现高可用, 存储使用CephRBD, RBD块设备是独占存储, 性能上要优于NAS存储.
这意味着同时只有一个实例在正常运行对外提供服务. 单实例的优点显而易见, RBD带来的性能优势, 部署上简单. 因为是公司内网使用, 对Harbor的并发读取操作很低, 极端情况下(几乎不可能出现)也只能有几千的并发. 所以单Harbor实例提供服务是可行的.
但是单实例存在一个单点故障的问题, 为了解决这个问题, 我们借助Keepalived的故障切换的能力实现故障转移. 缺点是, 在故障切换的过程中存在一定时间的服务不可用时间, 这个时间点多少取决于基础设置性能. 所以,总结来看改方案:

Advantage:

- RBD存储带来的性能优势
- 部署上简单易于维护和部署

Disadvantage:

- 故障转移期间服务不可用约几分钟

## Components

Using runit to manage these components:

- keepalived: check harbor and manage the vip
- harborctl: manage harbor instance, such as start stop status
- keepalivedctl: manage keepalived container, such as start status

## Requirements

- Kernel >= 4.5
- Kernel rbd module suport
- ceph-common 14.2: ceph codename <`nautilus`>
- docker-compose suport

## How to run

```
wget https://llaoj.oss-cn-beijing.aliyuncs.com/harbor-assistant/harbor-assistant.tar.gz -O - | tar -xzvf - -C /opt
cp /opt/harbor-assistant/harbor-assistant.service /usr/lib/systemd/system/
systemctl harbor-assistant start
```

## OS ENV

| ENV             | Required | Note                          |
| --------------- | -------- | ----------------------------- |
| HARBOR_VERSION  | Y        | only `v2.6.2` support for now |
| HARBOR_VIP      | Y        |                               |
| CEPH_MON_HOST   | Y        | comma separated               |
| CEPH_USER       | Y        |                               |
| CEPH_USER_KEY   | Y        |                               |
| CEPH_POOL_NAME  | Y        |                               |
| CEPH_IMAGE_NAME | Y        |                               |
| KEEPALIVED_ROLE | Y        | `master` or `backup`          |
| INTERFACE       | Y        | network dev interface         |


## Example

1. create rbd image

```
rbd create -p kubernetes harbor_data --size 2G --image-feature=layering
```

## Q&A

1. Failed to add secret to kernel

```shell
$ rbd device map kubernetes/harbor_data --id=admin --keyring=/etc/ceph/ceph.client.admin.keyring 
rbd: failed to add secret 'client.admin' to kernel
In some cases useful info is found in syslog - try "dmesg | tail".
rbd: map failed: (1) Operation not permitted
```

Docker prevent containers from using the kernel keyring, which is not namespaced. Run with `--security-opt seccomp=unconfined` option without the default seccomp profile.

2. Failed to load rbd kernel module

```shell
$ rbd device map kubernetes/harbor_data --id=admin --keyring=/etc/ceph/ceph.client.admin.keyring
sh: 1: /sbin/modinfo: not found
sh: 1: /sbin/modprobe: not found
rbd: failed to load rbd kernel module (127)
rbd: sysfs write failed
In some cases useful info is found in syslog - try "dmesg | tail".
rbd: map failed: (2) No such file or directory
```

Run `modprobe rbd` on the host to install rbd module
