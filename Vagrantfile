# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :master do |master|
    master.vm.box = "precise64"
    master.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"]  = "2048"
    end
    master.vm.provider :virtualbox do |v|
      v.name = "accumulo-devserver"
      v.customize ["modifyvm", :id, "--memory", "2048"]
    end
    master.vm.network :private_network, ip: "10.211.55.111"
    master.vm.hostname = "accumulo-devserver"
    master.vm.network "forwarded_port", guest: 2181, host: 2181
    master.vm.network "forwarded_port", guest: 50095, host: 5959
    master.vm.provision :shell, :path=> 'do_as_vagrant_user.sh'
  end

end

