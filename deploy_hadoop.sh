#!/bin/bash 

NODE_LIST="xiachsh21 xiachsh22 xiachsh23 xiachsh24 xiachsh25"
PASSWORD="Letmein123"


function setup_ssh_connection()
{
	rm -rf ~/.ssh
	ssh-keygen -t rsa -q -N "" -f ~/.ssh/id_rsa
	for node in $NODE_LIST;do
		expect -f ./setup_ssh $node $PASSWORD
	done
}
function scp_files()
{
	local_file=$1
	remote_dir=$2
	if [ -f $local_file ];then
		 
  	elif [ -d $local_file ];then
		
	fi
}

setup_ssh_connection

mkdir package/binary
mkdir package/src
cd package/binary 
##### download hadoop
wget http://www-us.apache.org/dist/hadoop/common/stable/hadoop-2.7.2.tar.gz
wget http://www-us.apache.org/dist/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz
wget http://www-us.apache.org/dist/hive/stable/apache-hive-1.2.1-bin.tar.gz
wget http://www-us.apache.org/dist/hbase/stable/hbase-1.1.4-bin.tar.gz
wget http://www-us.apache.org/dist/zookeeper/stable/zookeeper-3.4.8.tar.gz
cd -

cd package/src
http://www-us.apache.org/dist/hadoop/common/stable/hadoop-2.7.2-src.tar.gz
wget http://www-us.apache.org/dist/spark/spark-1.6.1/spark-1.6.1.tgz
wget http://www-us.apache.org/dist/hive/stable/apache-hive-1.2.1-src.tar.gz
wget http://www-us.apache.org/dist/hbase/stable/hbase-1.1.4-src.tar.gz
cd -

BINARY_LIST=$(find package/binary | sed -e "s#package/binary##")

