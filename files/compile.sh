#!/bin/bash

mvn_bin="/opt/app/apache-maven-3.3.9/bin/mvn"
echo $mvn_bin
echo "runtime:$1"
echo "path:`pwd`"

rm -f $2.tar.gz
$mvn_bin clean package -U -Dmaven.test.skip=true -P$1 -Dappname=$2 

tar xvf $2.tar.gz -C /tmp


