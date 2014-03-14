#!/bin/bash

ACCUMULO_VER=1.5.1
HADOOP_VER=1.2.1
ZOOKEEPER_VER=3.4.5

VAGRANT_HOME=/home/vagrant
ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER
HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER

cp -R /vagrant/files/bin $VAGRANT_HOME

echo "Acquiring Java and curl from Ubuntu repos..."
sudo apt-get -q update
sudo apt-get -q install curl openjdk-6-jdk -y

echo "Setting up environment..."
cat >> $VAGRANT_HOME/.bashrc <<EOF
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
export VAGRANT_HOME=/home/vagrant
export ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER
export HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
export ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER
export PATH=$PATH:$VAGRANT_HOME/bin:$HADOOP_HOME/bin:$ACCUMULO_HOME/bin
EOF

export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
export ACCUMULO_HOME=$VAGRANT_HOME/accumulo-$ACCUMULO_VER
export HADOOP_HOME=$VAGRANT_HOME/hadoop-$HADOOP_VER
export ZOOKEEPER_HOME=$VAGRANT_HOME/zookeeper-$ZOOKEEPER_VER
export PATH=$PATH:$HADOOP_HOME/bin:$ACCUMULO_HOME/bin

echo "Acquiring archives..."
cd /home/vagrant
echo "- Hadoop"
curl -O -L -s http://apache.mirrors.tds.net/hadoop/common/hadoop-$HADOOP_VER/hadoop-$HADOOP_VER.tar.gz
echo "- Zookeeper"
curl -O -L -s http://apache.mirrors.tds.net/zookeeper/zookeeper-$ZOOKEEPER_VER/zookeeper-$ZOOKEEPER_VER.tar.gz
echo "- Accumulo"
curl -O -L -s http://apache.mirrors.tds.net/accumulo/$ACCUMULO_VER/accumulo-$ACCUMULO_VER-bin.tar.gz

echo "Extracting archives..."
tar -zxf hadoop-$HADOOP_VER.tar.gz
tar -zxf zookeeper-$ZOOKEEPER_VER.tar.gz
tar -zxf accumulo-$ACCUMULO_VER-bin.tar.gz

echo "Configuring Hadoop..."
ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -N ''
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
ssh-keyscan localhost >> /home/vagrant/.ssh/known_hosts
cat >> $HADOOP_HOME/conf/hadoop-env.sh <<EOF
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/
EOF

cat > $HADOOP_HOME/conf/core-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:8020</value>
  </property>
  <property>
    <name>mapred.child.java.opts</name>
    <value>-Xmx512m</value>
  </property>
  <property>
    <name>analyzer.class</name>
    <value>org.apache.lucene.analysis.WhitespaceAnalyzer</value>
  </property>
  <property> 
    <name>hadoop.proxyuser.vagrant.hosts</name> 
    <value>*</value> 
  </property> 

  <property> 
    <name>hadoop.proxyuser.vagrant.groups</name> 
    <value>*</value> 
  </property> 
</configuration>

EOF
cat > $HADOOP_HOME/conf/mapred-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<!-- Put site-specific property overrides in this file. -->

<configuration>
   <property>
       <name>mapred.job.tracker</name>
       <value>localhost:8021</value>
   </property>
   <property>
       <name>mapred.child.java.opts</name>
       <value>-Xmx1024m</value>
   </property>
</configuration>

EOF
$HADOOP_HOME/bin/hadoop namenode -format

echo "Starting Hadoop..."
$HADOOP_HOME/bin/start-all.sh

echo "Configuring Zookeeper..."
sudo mkdir /var/zookeeper
sudo chown vagrant:vagrant /var/zookeeper

cp $ZOOKEEPER_HOME/conf/zoo_sample.cfg $ZOOKEEPER_HOME/conf/zoo.cfg

echo "Running Zookeeper..."
$ZOOKEEPER_HOME/bin/zkServer.sh start

echo "Configuring Accumulo..."
cp $ACCUMULO_HOME/conf/examples/1GB/standalone/* $ACCUMULO_HOME/conf/

cat > $ACCUMULO_HOME/conf/masters <<EOF
accumulo-dev-box
EOF

cat > $ACCUMULO_HOME/conf/slaves <<EOF
accumulo-dev-box
EOF

cat > $ACCUMULO_HOME/conf/monitor <<EOF
accumulo-dev-box
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

