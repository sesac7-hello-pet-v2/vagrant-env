#!/bin/bash
set -e

# 1. kubeadm으로 클러스터 초기화
echo " Initializing Kubernetes cluster with kubeadm"
# --apiserver-advertise-address는 Private Network의 IP로 지정해야 합니다.
# --pod-network-cidr은 Calico CNI가 사용할 IP 대역입니다.
kubeadm init --apiserver-advertise-address=10.10.10.10 --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU

# 2. vagrant 사용자를 위한 kubeconfig 설정
echo " Setting up kubeconfig for vagrant user"
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

echo "Setting up kubectl command autocompletion for all users"
apt-get update >/dev/null 2>&1
apt-get install -y bash-completion >/dev/null 2>&1
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >> /home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc

# # 3. Calico CNI 네트워크 플러그인 배포
# echo " Deploying Calico CNI network plugin"
# su - vagrant -c "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml"
# su - vagrant -c "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml"

# 3. Calico CNI 네트워크 플러그인 배포
echo "[INFO] Deploying Calico CNI network plugin"

# 3.1. Tigera Operator 설치
su - vagrant -c "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml"

# 3.2. 올바른 설정이 포함된 Custom Resource Manifest를 직접 생성하여 적용
echo "[INFO] Applying patched Calico Custom Resource"
cat <<EOF | sudo tee /tmp/calico-cr.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    nodeAddressAutodetectionV4:
      cidrs:
        - 10.10.10.0/24
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLAN
      natOutgoing: Enabled
      nodeSelector: all()
EOF

# vagrant 사용자로 위에서 생성한 임시 파일을 클러스터에 적용합니다.
su - vagrant -c "kubectl apply -f /tmp/calico-cr.yaml"

echo " Removing control-plane taint from master node to allow scheduling pods"
su - vagrant -c "kubectl taint nodes --all node-role.kubernetes.io/control-plane-"

# 4. 워커 노드가 조인할 명령어 생성 및 공유
echo " Generating and saving the cluster join command"
mkdir -p /vagrant/configs
kubeadm token create --print-join-command > /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh

# 5. 호스트에서 kubectl을 사용하기 위한 kubeconfig 파일 복사
cp /etc/kubernetes/admin.conf /vagrant/configs/config

echo "Master node setup complete."