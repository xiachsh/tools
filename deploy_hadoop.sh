#!/bin/bash 

NODE_LIST="xiachsh21 xiachsh22 xiachsh23 xiachsh24 xiachsh25"
PASSWORD="Letmein123"
TARGET_PATH="/opt/apache"


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
	local_path=$1
	remote_dir=$2
	if [ -f $local_path ];then
		for node in $NODE_LIS;do
			ssh $node mkdir -p $remote_dir
			scp $local_path $node:$remote_dir
		done		 
  	elif [ -d $local_path ];then
		for node in $NODE_LIST;do
                        ssh $node mkdir -p $remote_dir
                        scp  -r $local_path/* $node:$remote_dir
                done             
	fi
}
function remote_untar()
{
	tarball=$1
	target_path=$2
	for node in $NODE_LIST;do
		ssh $node mkdir -p $target_path
		untar_option="zxvf"
		if echo $tarball | grep "tar$" >/dev/null 2>&1;then
			untar_option="xvf"
		fi
		ssh $node tar $untar_option -C $target_path	
	done
}

setup_ssh_connection

mkdir -p  package/binary
mkdir -p  package/src
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

scp_files "package/binary" "/tmp"

BINARY_TARBALL_LIST=$(find package/binary | sed -e "s#package/binary##")
for binary_tarball in $BINARY_TARBALL_LIST;do
	remote_untar /tmp/$binary_tarball $TARGET_PATH	
done


