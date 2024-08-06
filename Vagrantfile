# yosp test

Vagrant.configure("2") do |config|

  config.vm.define "yosp" do |yosp|
    yosp.vm.box = "bento/centos-stream-9"
    yosp.vm.define "yosp" # update default vm definition name
    yosp.vm.hostname = "yosp"
    yosp.vm.synced_folder "./apache", "/vagrant_files", disabled: false
    yosp.vm.network "public_network", # public network
      use_dhcp_assigned_default_route: true
    yosp.vm.provider "vmware_desktop" do |vmware1|
      vmware1.vmx["memsize"] = "1024"
      vmware1.vmx["numvcpus"] = "1"
    end
    yosp.vm.post_up_message = "small VPS"
  end
  
end
