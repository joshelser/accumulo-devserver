#!/bin/bash

ACCUMULO_VER_FILE=1.6.0.RC1
ACCUMULO_VER=1.6.0
HADOOP_VER=2.4.0
ZOOKEEPER_VER=3.4.5

#
# Setup env variables for vagrant
#

VAGRANT_HOME=/home/vagrant
HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
HADOOP_MAPRED_HOME=$HADOOP_HOME
HADOOP_COMMON_HOME=$HADOOP_HOME
HADOOP_HDFS_HOME=$HADOOP_HOME
HADOOP_YARN_HOME=$HADOOP_HOME
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER
ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER

HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native 
HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"

cp -R /vagrant/files/* $VAGRANT_HOME

echo "Acquiring Java and curl from Ubuntu repos..."
sudo apt-get -q update
sudo apt-get -q install curl openjdk-7-jdk -y

echo "Setting up environment..."
cat >> $VAGRANT_HOME/.bashrc <<EOF
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/
export VAGRANT_HOME=/home/vagrant
export ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER
export HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native 
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"
EOF

export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/
export ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER
export ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER
export HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native 
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib"

sudo sysctl vm.swappiness=0

#
# For some reason I get a permission denied when
# just trying to write the new value.  Update the
# perms before writing, then restore them.
#
sudo chmod 777 /etc/sysctl.conf
echo "vm.swappiness = 0" >> /etc/sysctl.conf
echo "# disable ipv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sudo chmod 644 /etc/sysctl.conf

#
# Reload the changes from sysctl
#
sudo sysctl -p

cd $VAGRANT_HOME

echo "Acquiring archives..."
echo "- Hadoop"
cd tars

curl -O -L http://apache.mirrors.tds.net/hadoop/common/hadoop-$HADOOP_VER/hadoop-$HADOOP_VER.tar.gz

cd ..

echo "Extracting archives..."
echo "Hadoop $HADOOP_VER"
tar -zxf tars/hadoop-$HADOOP_VER.tar.gz
echo "Zookeeper $ZOOKEEPER_VER"
tar -zxf tars/zookeeper-$ZOOKEEPER_VER.tar.gz
echo "Accumulo $ACCUMULO_VER"
tar -zxf tars/accumulo-$ACCUMULO_VER_FILE-bin.tar.gz

echo "Configuring Hadoop..."

ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -N ''
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
ssh-keyscan localhost >> /home/vagrant/.ssh/known_hosts

cat > /home/vagrant/.ssh/config <<EOF
Host localhost
    Hostname 0.0.0.0
    StrictHostKeyChecking no
EOF

mkdir -p ~/data/hadoop/yarn-data/hdfs/namenode
mkdir -p ~/data/hadoop/yarn-data/hdfs/datanode

sudo chown vagrant:vagrant -R ~/data/hadoop/yarn-data
sudo chmod 750 ~/data/hadoop/yarn-data

sed -i 's,${JAVA_HOME},/usr/lib/jvm/java-7-openjdk-amd64/,' $HADOOP_CONF_DIR/hadoop-env.sh

cat > $HADOOP_CONF_DIR/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF

cat > $HADOOP_CONF_DIR/yarn-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>
</configuration>
EOF

cat > $HADOOP_CONF_DIR/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF

cat > $HADOOP_CONF_DIR/hdfs-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:/home/vagrant/data/hadoop/yarn-data/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:/home/vagrant/data/hadoop/yarn-data/hdfs/datanode</value>
  </property>
</configuration>
EOF


$HADOOP_HOME/bin/hdfs namenode -format


echo "Starting Hadoop..."
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo "Configuring Zookeeper..."
sudo mkdir /var/zookeeper
sudo chown vagrant:vagrant /var/zookeeper

cp $ZOOKEEPER_HOME/conf/zoo_sample.cfg $ZOOKEEPER_HOME/conf/zoo.cfg
sed -i 's,/tmp/zookeeper,/home/vagrant/data/zookeeper,' zookeeper-3.4.5/conf/zoo.cfg

echo "Running Zookeeper..."
$ZOOKEEPER_HOME/bin/zkServer.sh start

echo "Configuring Accumulo..."
cp $ACCUMULO_HOME/conf/examples/1GB/standalone/* $ACCUMULO_HOME/conf/

cat > $ACCUMULO_HOME/conf/masters <<EOF
accumulo-devserver
EOF

cat > $ACCUMULO_HOME/conf/slaves <<EOF
accumulo-devserver
EOF

cat > $ACCUMULO_HOME/conf/monitor <<EOF
accumulo-devserver
EOF

cat > $ACCUMULO_HOME/conf/gc <<EOF
accumulo-devserver
EOF

cat > $ACCUMULO_HOME/conf/tracers <<EOF
accumulo-devserver
EOF

sed -i 's/>secret</>password</' $ACCUMULO_HOME/conf/accumulo-site.xml

$ACCUMULO_HOME/bin/accumulo init --clear-instance-name <<EOF
accumulo
password
password
EOF

echo "Starting Accumulo..."
$ACCUMULO_HOME/bin/start-all.sh

echo 'Done!'
