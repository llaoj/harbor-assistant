## 环境要求

- Kernel>=4.5
- Ceph-common version >= ceph version
- Ceph code name: `nautilus`

## 方案介绍

部署两个Harbor实例来实现高可用, 存储使用CephRBD, RBD块设备是独占存储, 性能上要优于NAS存储.
这意味着同时只有一个实例在正常运行对外提供服务. 单实例的优点显而易见, RBD带来的性能优势, 部署上简单. 因为是公司内网使用, 对Harbor的并发读取操作很低, 极端情况下(几乎不可能出现)也只能有几千的并发. 所以单Harbor实例提供服务是可行的.
但是单实例存在一个单点故障的问题, 为了解决这个问题, 我们借助Keepalived的故障切换的能力实现故障转移. 缺点是, 在故障切换的过程中存在一定时间的服务不可用时间, 这个时间点多少取决于基础设置性能. 所以,总结来看改方案:

优势:

- RBD存储带来的性能优势
- 部署上简单易于维护和部署

缺点:

- 故障转移期间服务不可用约几分钟

## 主要组件

Using runit to manage these components:

- Keepalived
- `harbor-healthz.sh` used by Keepalived
- `failover.sh` start or cleanup Harbor instance when fault occurs

## How to run

Run this contianer<`registry.cn-beijing.aliyuncs.com/llaoj/harbor-failover-with-rbd`> beside Harbor, you need add some options:

```sh
docker run \
  -d \
  --name harbor-failover
  --cap-add=NET_ADMIN \
  --cap-add=NET_BROADCAST \
  --cap-add=NET_RAW \
  --net=host \
  -e CEPH_POOL_NAME= \
  -e CEPH_IMAGE_NAME= \
  -e CEPH_MON_HOST= \
  -e CEPH_USER= \
  -e CEPH_USER_KEY= \
  -e KEEPALIVED_VIP= \
  -e KEEPALIVED_ROLE=master \
  registry.cn-beijing.aliyuncs.com/llaoj/harbor-failover-with-rbd
```

## OS ENV

| ENV             | Required | Note                 |
| --------------- | -------- | -------------------- |
| CEPH_POOL_NAME  | Y        |                      |
| CEPH_IMAGE_NAME | Y        |                      |
| CEPH_MON_HOST   | Y        |                      |
| CEPH_USER       | Y        |                      |
| CEPH_USER_KEY   | Y        |                      |
| KEEPALIVED_VIP  | Y        |                      |
| KEEPALIVED_ROLE | Y        | `master` or `backup` |

