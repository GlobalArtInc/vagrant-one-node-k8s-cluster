require "yaml"
vagrant_root = File.dirname(File.expand_path(__FILE__))
settings = YAML.load_file("#{vagrant_root}/settings.yaml")

IP_SECTIONS = settings["network"]["control_ip"].match(/^([0-9.]+\.)([^.]+)$/)
# First 3 octets including the trailing dot:
IP_NW = IP_SECTIONS.captures[0]
# Last octet excluding all dots:
IP_START = Integer(IP_SECTIONS.captures[1])

Vagrant.configure("2") do |config|
  if `uname -m`.strip == "aarch64"
    config.vm.box = settings["software"]["box"] + "-arm64"
  else
    config.vm.box = settings["software"]["box"]
  end
  config.vm.box_check_update = true
  
  config.disksize.size = "500GB"
  
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: settings["network"]["control_ip"]
    if settings["shared_folders"]
      settings["shared_folders"].each do |shared_folder|
        master.vm.synced_folder shared_folder["host_path"], shared_folder["vm_path"]
      end
    end
    master.vm.provider "virtualbox" do |vb|
      vb.cpus = settings["nodes"]["master"]["cpu"]
      vb.memory = settings["nodes"]["master"]["memory"]
      if settings["cluster_name"] and settings["cluster_name"] != ""
        vb.customize ["modifyvm", :id, "--groups", ("/" + settings["cluster_name"])]
      end
    end

    # master.vm.provision "shell", path: "scripts/disk-extend.sh"
    master.vm.provision "shell",
      env: {
        "DNS_SERVERS" => settings["network"]["dns_servers"].join(" "),
        "ENVIRONMENT" => settings["environment"],
        "KUBERNETES_VERSION" => settings["software"]["kubernetes"],
        "KUBERNETES_VERSION_SHORT" => settings["software"]["kubernetes"][0..3],
        "OS" => settings["software"]["os"]
      },
      path: "scripts/common.sh"
    master.vm.provision "shell",
      env: {
        "CALICO_VERSION" => settings["software"]["calico"],
        "CONTROL_IP" => settings["network"]["control_ip"],
        "POD_CIDR" => settings["network"]["pod_cidr"],
        "SERVICE_CIDR" => settings["network"]["service_cidr"]
      },
      path: "scripts/master.sh"
  end
end
