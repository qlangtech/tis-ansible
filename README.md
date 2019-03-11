# 使用方法
1.inventory示例
```
[solr5-kr]
#主机名不能解析的情况下指定IP
solr001 ansible_ssh_host=10.33.9.192
```

2.在执行playbook前，确认主机能正常ssh过去
```
ansible solr5-kr -m ping
ansible solr001 -m ping
```

3.重启solr服务,注意要加上'--become'才能得到sudo权限

```
ansible solr6 -i ./inventory/kr-online -m service --become  -a "name=spring-boot state=restarted"
```


4. mysql dump 

mysqldump -d -uxx -pxxx -h127.0.0.1  tis_console > tis_console.sql

the option '-d' means nodata just table struct

5. 添加Role： ansible-galaxy init --init-path=roles taskcenter-worker

6. 构建某一个Task
