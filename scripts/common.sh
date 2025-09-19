#!/bin/bash
set -e # 스크립트 실행 중 오류 발생 시 즉시 중단

echo "Disabling and stopping ufw firewall"
systemctl stop ufw
systemctl disable ufw

# 1. 시스템 업데이트 및 필수 패키지 설치
echo " Updating system and installing essential packages"
apt-get update >/dev/null 2>&1
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg-agent >/dev/null 2>&1

# 2. 스왑 비활성화 (쿠버네티스 공식 요구사항)
echo " Disabling swap"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 3. 커널 모듈 로드 및 sysctl 설정 (컨테이너 네트워크를 위함)
echo " Configuring kernel modules and sysctl for Kubernetes networking"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
sudo modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null 2>&1

# # 4. Containerd 런타임 설치
# echo " Installing containerd runtime"
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
# apt-get update >/dev/null 2>&1
# apt-get install -y containerd.io >/dev/null 2>&1
# mkdir -p /etc/containerd
# containerd config default | tee /etc/containerd/config.toml
# sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
# systemctl restart containerd
# systemctl enable containerd >/dev/null 2>&1

# 4. Containerd 런타임 설치
echo "[INFO] Installing containerd runtime"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update >/dev/null 2>&1
apt-get install -y containerd.io >/dev/null 2>&1

# --- 설정 변경 부분 시작 ---
echo "[INFO] Configuring containerd"
# containerd 설정 파일 디렉토리 생성
sudo mkdir -p /etc/containerd

# containerd 기본 설정 파일 생성 (매번 덮어쓰기)
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

# SystemdCgroup 설정 변경
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# [추가] insecure-registries 설정 추가 (더 안정적인 방식으로 수정)
# [plugins."io.containerd.grpc.v1.cri".registry] 섹션 바로 아래에 미러 설정을 추가합니다.
sudo sed -i '/\[plugins."io.containerd.grpc.v1.cri".registry\]/a \ \ \ \ \ \ \ \ [plugins."io.containerd.grpc.v1.cri".registry.mirrors."10.10.10.1:5000"]\n\ \ \ \ \ \ \ \ \ \ endpoint = ["http://10.10.10.1:5000"]' /etc/containerd/config.toml

# --- 설정 변경 부분 끝 ---

# 모든 설정 변경 후 containerd 재시작 및 활성화
echo "[INFO] Restarting containerd"
sudo systemctl restart containerd
sudo systemctl enable containerd >/dev/null 2>&1

# 5. 쿠버네티스 패키지(kubeadm, kubelet, kubectl) 설치
echo " Installing Kubernetes components (kubeadm, kubelet, kubectl)"
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key -o /tmp/kubernetes-apt-keyring.asc
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg /tmp/kubernetes-apt-keyring.asc
rm /tmp/kubernetes-apt-keyring.asc
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Common setup complete."

# --- [ADD] Force kubelet to use host-only IP (10.10.10.0/24) ---
NODE_IP=$(ip -o -4 addr show | awk '$4 ~ /^10\.10\.10\./ {print $4}' | cut -d/ -f1 | head -n1)
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet
# --- [END ADD] ---
