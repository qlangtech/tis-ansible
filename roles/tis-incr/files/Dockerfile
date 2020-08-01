FROM centos:7
#build commend  docker build -t tis/tis-incr  .
MAINTAINER baisui <baisui@qlangtech.com>

#WORKDIR /srv/ansible
#RUN ansible localhost -c local -m ping -vvvv
#RUN ansible localhost -c local  -a "repo=git@github.com:qlangtech/tis-ansible.git dest=/srv/ansible version='master' accept_hostkey=true" -m git

RUN INSTALL_PKGS="tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel" && \
    yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y && \
	mkdir -p /opt/logs && chmod -R 777 /opt/logs && \
    mkdir -p /opt/tis &&  chmod -R a+rwX /opt/tis && \
    chmod g=u /etc/passwd

ADD tis-incr.tar.gz /opt/tis/

ENTRYPOINT ["/opt/tis/run.sh"]

