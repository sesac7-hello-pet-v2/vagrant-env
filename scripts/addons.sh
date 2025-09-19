#!/bin/bash

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

echo "===== 1. MetalLB 설치 시작 ====="
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
echo "MetalLB 매니페스트를 적용했습니다. 파드가 준비될 때까지 기다립니다..."
echo ""

# -----------------------------------------------------------------------------

echo "===== 2. MetalLB 파드 준비 상태 확인 ====="
# metallb-system 네임스페이스의 모든 파드가 Ready 상태가 될 때까지 최대 5분 대기
kubectl wait --for=condition=Ready pod --all -n metallb-system --timeout=300s
echo "MetalLB의 모든 파드가 준비되었습니다."
echo ""

# -----------------------------------------------------------------------------

echo "===== 3. MetalLB 설정 (IPAddressPool, L2Advertisement) 적용 ====="
cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: vagrant-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.10.10.200-10.10.10.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: vagrant-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - vagrant-pool
EOF
echo "MetalLB IP 주소 풀 설정이 완료되었습니다."
echo ""

# -----------------------------------------------------------------------------

echo "===== 4. NGINX Ingress Controller 설치 시작 ====="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
echo "NGINX Ingress Controller 매니페스트를 적용했습니다. 파드가 준비될 때까지 기다립니다..."
echo ""

# -----------------------------------------------------------------------------

echo "===== 5. NGINX Ingress Controller 파드 준비 상태 확인 ====="
# ingress-nginx 네임스페이스의 모든 파드가 Ready 상태가 될 때까지 최대 5분 대기
# Admission Webhook 파드가 준비되지 않으면 다음 단계의 patch가 실패할 수 있으므로 이 단계가 중요합니다.
kubectl wait --for=condition=Ready pod --all -n ingress-nginx --timeout=300s
echo "NGINX Ingress Controller의 모든 파드가 준비되었습니다."
echo ""

# -----------------------------------------------------------------------------

echo "===== 6. NGINX Service를 LoadBalancer 타입으로 변경 ====="
kubectl -n ingress-nginx patch svc ingress-nginx-controller -p '{"spec":{"type":"LoadBalancer"}}'
echo "Service 타입을 LoadBalancer로 변경했습니다. MetalLB가 EXTERNAL-IP를 할당합니다."
echo ""

# -----------------------------------------------------------------------------

echo "===== 7. kubeconfig를 호스트와 공유하기 위한 설정 ====="

# Vagrant 공유 폴더에 configs 디렉토리 생성
if [ ! -d "/vagrant/configs" ]; then
    mkdir -p /vagrant/configs
    echo "공유 폴더 /vagrant/configs 생성 완료"
fi

# admin.conf를 공유 폴더로 복사
if [ -f "/etc/kubernetes/admin.conf" ]; then
    sudo cp /etc/kubernetes/admin.conf /vagrant/configs/config
    # vagrant 사용자가 읽을 수 있도록 권한 변경
    sudo chown $(id -u vagrant):$(id -g vagrant) /vagrant/configs/config
    echo "kubeconfig 파일이 /vagrant/configs/config로 복사되었습니다."
    echo ""
    echo "===== 호스트 PC에서 kubectl 설정 방법 ====="
    echo "1. 호스트 PC의 터미널에서 다음 명령을 실행하세요:"
    echo ""
    echo "   # Windows (Git Bash)"
    echo "   mkdir -p ~/.kube"
    echo "   cp ./configs/config ~/.kube/config"
    echo ""
    echo "   # Mac/Linux"
    echo "   mkdir -p ~/.kube"  
    echo "   cp ./configs/config ~/.kube/config"
    echo ""
    echo "2. 설정 확인:"
    echo "   kubectl get nodes"
    echo ""
else
    echo "경고: /etc/kubernetes/admin.conf 파일을 찾을 수 없습니다."
    echo "이 스크립트가 마스터 노드에서 실행되고 있는지 확인하세요."
fi

echo "===== 모든 설정이 완료되었습니다! ====="