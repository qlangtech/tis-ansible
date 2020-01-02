# 使用方法

## 介绍

该脚本集成了下面一些功能：

- 系统初始化：安装必备的软件，并做一些设置
- 安装系统依赖的jdk、spring-boot
- 安装 zookeeper
- 安装 hadoop 的 hdfs、 yarn
- 安装 spark，支持tidb的 tispark，方便通过jdbc连接的 thriftserver及对应yarn的spark-shuffle
- 安装 solr
- 安装 tis-console、tis-assemble
- 安装对应全量构建需要的 index-builder

脚本在 CentOS 7.6 上通过测试。

## 准备阶段

inventory/hosts 文件示例如下，为了自动生成 hosts 文件，请在主机名后通过 ansible_ssh_host 指定IP：

```file
[solr7.6]
solr1.xxx ansible_ssh_host=10.33.9.192
solr2.xxx ansible_ssh_host=10.33.9.193

[hadoop-hdfs-datanode]
hadoop1.xxx ansible_ssh_host=10.1.1.1
hadoop2.xxx ansible_ssh_host=10.1.1.2
hadoop3.xxx ansible_ssh_host=10.1.1.3
```

其中 solr7.6 为一组主机，solr1.xxx 为单个主机，下面的操作都会指定一组主机或单个主机。

另外需要配置 vars.yml 文件，修改下面几个参数以定制安装需要的组件，如果不安装，则需要确保这些主机已经是可用状态：
> need_install_zookeeper: true
need_install_hadoop: true
need_install_spark: true
need_install_tispark: true
need_install_spark_shuffle: true

具体依赖关系看其中的注释。

## 确保主机可以由中控机ssh免密登陆

如果在ansible中控机没有做过 ssh-copy-id 到其它需要安装的主机，可以通过 ssh-keygen 先在中控机生成一个可以，使用下面的命令可以通过 `copy_root_sshkey.yml` 辅助拷贝到其它主机，注意如果需要一组或多组主机拷贝，则要确保一组主机有相同的root密码：

```shell
ansible solr7.6,hadoop-hdfs-datanode -m authorized_key -a "user=root key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}'" -k
ansible solr1.xxx -m authorized_key -a "user=root key='{{ lookup('file', '/root/.ssh/id_rsa.pub') }}'" -k
```

然后可以通过下面的方式验证是否实现了免密登陆，可以一次性测试多组主机：

```shell
ansible solr7.6,hadoop-hdfs-datanode -m ping
ansible solr1.xxx -m ping
```

## 通过已经发布的releas文件安装

cd 到ansible脚本所在目录：

```shell
ansible-playbook ./deploy-tis-by-release.yml
```

## 启动和停止系统

```shell
# 启动系统
ansible-playbook ./start.yml
# 停止系统
ansible-playbook ./stop.yml
```

## 初始化tis

第一次安装tis，需要向mysql数据库中，初始化数据库，其中的sql是通过下面的命令导出的：

```shell
# the option '-d' means nodata just table struct
mysqldump -d -uxx -pxxx -h127.0.0.1  tis_console > tis_console.sql
```

在启动tis后，可以通过 tis.xx:8080 通过web访问系统，需要初始化几个值：

- zkaddress：设置为几个主机，后加 `/tis/cloud` 路径，`zk1.aim:2181,zk2.aim:2181,zk3.aim:2181/tis/cloud`
- tis_hdfs_root_dir: 设置为如下路径 `/xxx/data`，不需要前面类似于 `hdfs://hadoop1.xxx:9000` 这样的URL。

3.重启solr服务,注意要加上'--become'才能得到sudo权限

```file
ansible solr7.6 -i ./inventory/hosts -m service --become  -a "name=spring-boot state=restarted"
```

## 向ansible脚本中新添加一个role

```shell
ansible-galaxy init --init-path=roles taskcenter-worker
```
