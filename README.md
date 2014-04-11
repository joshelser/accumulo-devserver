# Introduction

Spins up a VM with Hadoop, Zookeeper and Accumulo.
- Hadoop 2.4.0
- Zookeeper 3.4.5
- Accumulo 1.6.0-RC1

# Getting Started

1. [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. [Install Vagrant](http://downloads.vagrantup.com)
3. Clone this project
4. Run ```vagrant up``` from within the project directory. You'll need at least 2Gb free.
5. Run ```vagrant ssh``` from within the project directory to get into your VM, or open up the VirtualBox
   Manager app to tweak settings, forward ports, etc.
6. The app can now be accessed at port 10.211.55.111. To make it accessible at "accumulo-devbox", add
   the following to the end of your /etc/hosts file: ```10.211.55.111 accumulo-devbox```
7. To connect to it from a client:
  - Instance name: accumulo
  - Zookeeper server: localhost:2181
