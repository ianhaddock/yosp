# yospace test

Vagrant.configure("2") do |config|

  config.vm.define "yospace" do |yospace|
    yospace.vm.box = "bento/centos-stream-9"
    yospace.vm.define "yospace" # update default vm definition name
    yospace.vm.hostname = "yospace"
    yospace.vm.synced_folder "./vagrant", "/vagrant", disabled: false
    yospace.vm.network "public_network", # public network
      use_dhcp_assigned_default_route: true
    yospace.vm.provider "vmware_desktop" do |vmware1|
      vmware1.vmx["memsize"] = "1024"
      vmware1.vmx["numvcpus"] = "1"
    end
    yospace.vm.post_up_message = "small VPS"
  end
  
end
