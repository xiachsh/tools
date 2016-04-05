#!/bin/bash 

NODE_LIST="xiachsh21 xiachsh22 xiachsh23 xiachsh24 xiachsh25"
SLAVES_LIST="xiachsh22 xiachsh23 xiachsh24 xiachsh25"
PASSWORD="Letmein123"
TARGET_PATH="/opt/apache"
MASTER="xiachsh21"


function setup_ssh_connection()
{
	rm -rf ~/.ssh
	ssh-keygen -t rsa -q -N "" -f ~/.ssh/id_rsa
	for node in $NODE_LIST;do
		expect -f ./setup_ssh $node $PASSWORD
	done
}

function ssh_cmd()
{
	cmd=$1
	if [[ -z $cmd ]];then
		return 
	fi
	for node in $NODE_LIS;do
		ssh $node $cmd
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
		ssh $node tar $untar_option $tarball -C $target_path	
	done
}
function remove_path()
{
	dir=$1
	for node in $NODE_LIST;do
		ssh $node rm -rf $dir
	done
}

function update_master_slave_list()
{
	echo $MASTER > /opt/apache/hadoop-2.7.2/etc/hadoop/masters
	rm -rf /opt/apache/hadoop-2.7.2/etc/hadoop/slaves
	for SLAVE in $SLAVES_LIST;do
		echo $SLAVE >> /opt/apache/hadoop-2.7.2/etc/hadoop/slaves 
	done
}
function update_hadoop_env()
{
	sed -i 's#export JAVA_HOME=${JAVA_HOME}#export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64#' /opt/apache/hadoop-2.7.2/etc/hadoop/hadoop-env.sh	
	sed -i 's#export HADOOP_CONF_DIR.*#export HADOOP_CONF_DIR=/opt/apache/hadoop-2.7.2/etc/hadoop/#' /opt/apache/hadoop-2.7.2/etc/hadoop/hadoop-env.sh
}

function update_core_default()
{
	 sed -i '/fs.defaultFS/,+3 s#<value>file:///</value>#<value>hdfs://xiachs21/</value>#' /opt/apache/hadoop-2.7.2/etc/hadoop/core-default.xml 
}

function update_hdfs_default()
{
	ssh_cmd mkdir -p /hadoop/dfs/name
	ssh_cmd mkdir -p /hadoop/dfs/data	

	sed -i '/<name>dfs.datanode.data.dir<\/name>/,+3 s#<value>file://${hadoop.tmp.dir}/dfs/data</value># <value>file://hadoop/dfs/data</value>#' /opt/apache/hadoop-2.7.2/etc/hadoop/hdfs-default.xml
	sed -i '/<name>dfs.namenode.name.dir<\/name>/,+3 s#<value>file://${hadoop.tmp.dir}/dfs/name</value># <value>file://hadoop/dfs/name</value>#' /opt/apache/hadoop-2.7.2/etc/hadoop/hdfs-default.xml
	sed -i '/<name>dfs.replication<\/name>/,+3 s#<value>3</value>#<value>1</value>#' /opt/apache/hadoop-2.7.2/etc/hadoop/hdfs-default.xml
}





function update_conf_file()
{
	scp_files 	/opt/apache/hadoop-2.7.2/etc/hadoop/ /opt/apache/hadoop-2.7.2/etc/hadoop/
}


setup_ssh_connection

if [ -d package/binary ];then
	rm -rf package/binary/*
fi
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

for binary_tarball in $BINARY_TARBALL_LIST;do
	remove_path	 /tmp/$binary_tarball 
done



find /opt/apache/hadoop-2.7.2 -name "*-default.xml" -exec cp {} /opt/apache/hadoop-2.7.2/etc/hadoop \;
update_master_slave_list
update_hadoop_env
update_core_default
update_hdfs_default

update_conf_file
