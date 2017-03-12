# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'

Vagrant.require_version ">= 1.6.0"

CONSUL_CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "generated" , "consul-cloud-config.yaml")
ETCD3_CLOUD_CONFIG_PATH = File.join(File.dirname(__FILE__), "generated", "etcd3-cloud-config.yaml")

# Defaults for config options defined in CONFIG
$num_instances = 3
$update_channel = "stable"
$image_version = "current"

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false
  # forward ssh agent to easily ssh into the different machines
  config.ssh.forward_agent = true

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-landrush") then
    config.landrush.enabled = true
  end

  config.vm.box = "coreos-%s" % $update_channel
  if $image_version != "current"
      config.vm.box_version = $image_version
  end
  config.vm.box_url = "https://storage.googleapis.com/%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.define consul_name = "consul" do |consul|
    consul.vm.hostname = consul_name

    ip = "172.17.8.50"
    consul.vm.network :private_network, ip: ip

    if File.exist?(CONSUL_CLOUD_CONFIG_PATH)
      consul.vm.provision :file, :source => "#{CONSUL_CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
      consul.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "etcd-%d" % i do |config|
      config.vm.hostname = vm_name

      ip = "172.17.8.#{i+100}"
      config.vm.network :private_network, ip: ip

      if File.exist?(ETCD3_CLOUD_CONFIG_PATH)
        config.vm.provision :file, :source => "#{ETCD3_CLOUD_CONFIG_PATH}", :destination => "/tmp/vagrantfile-user-data"
        config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      end

    end
  end
end
