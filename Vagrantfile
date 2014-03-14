# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :master do |master|
    master.vm.box = "precise64"
    master.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"]  = "2048"
    end
    master.vm.provider :virtualbox do |v|
      v.name = "accumulo-dev-box"
      v.customize ["modifyvm", :id, "--memory", "2048"]
    end
    master.vm.network :private_network, ip: "10.211.55.100"
    master.vm.hostname = "accumulo-dev-box"
    master.vm.network "forwarded_port", guest: 35867, host: 35867
    master.vm.network "forwarded_port", guest: 50095, host: 50095
    master.vm.network "forwarded_port", guest: 50030, host: 50030
    master.vm.network "forwarded_port", guest: 50060, host: 50060
    master.vm.network "forwarded_port", guest: 54310, host: 54310
    master.vm.network "forwarded_port", guest: 54311, host: 54311
    master.vm.provision :shell, :path=> 'do_as_vagrant_user.sh'
  end

end

