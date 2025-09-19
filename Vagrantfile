# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_WORKER_NODES = 1
IP_NETWORK       = "10.10.10"
BOX              = "ubuntu/focal64"

# 공통 리소스 기본값 (필요하면 아래 define_node 호출 시 override 가능)
VM_CPUS   = 1
VM_MEMORY = 3072
PROJECT   = File.basename(Dir.pwd)

# 공통 정의 함수
def define_node(config, name:, ip:, role:, memory: VM_MEMORY, cpus: VM_CPUS)
  config.vm.define name do |node|
    node.vm.hostname = name
    node.vm.network "private_network", ip: ip

    # 공통 VirtualBox 설정
    node.vm.provider "virtualbox" do |vb|
      vb.name   = "#{PROJECT}-#{name}"
      vb.memory = memory
      vb.cpus   = cpus
      vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
      vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
      vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
      vb.customize [ "modifyvm", :id, "--cableconnected1", "on" ]
    end

    # 공통 프로비저너
    node.vm.provision "shell", path: "scripts/common.sh"

    # 역할별 프로비저너
    case role
    when :master
      node.vm.provision "shell", path: "scripts/master.sh"
      node.vm.provision "shell", path: "scripts/addons.sh", privileged: false
    when :worker
      node.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = BOX

  # 마스터
  define_node(config,
    name: "master-node",
    ip:   "#{IP_NETWORK}.10",
    role: :master
  )

  # 워커들
  (1..NUM_WORKER_NODES).each do |i|
    define_node(config,
      name: "worker-node-#{i}",
      ip:   "#{IP_NETWORK}.#{10 + i}",
      role: :worker
    )
  end
end
