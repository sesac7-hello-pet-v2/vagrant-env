# Vagrant Kubernetes Lab

Vagrant/VirtualBox 기반의 로컬 쿠버네티스 실습 환경입니다.
마스터 1대 + 워커 N대 구조이며, CNI는 **Calico**, 로드밸런서는 **MetalLB**, Ingress는 **NGINX Ingress Controller**를 사용합니다.

---

## 📦 구성 개요

* **베이스 OS**: Ubuntu 20.04 (`ubuntu/focal64`)
* **런타임**: containerd (`SystemdCgroup=true`)
* **쿠버네티스 버전**: 1.28 (kubeadm/kubelet/kubectl)
* **CNI**: Calico (VXLAN, CIDR: `192.168.0.0/16`)
* **로드밸런서**: MetalLB (`10.10.10.200-250` 풀 할당)
* **Ingress**: NGINX Ingress Controller (LoadBalancer 타입)

---

## 🚀 사용법

1. **VM 실행**

   ```bash
   vagrant up
   ```

2. **클러스터 상태 확인**

   ```bash
   vagrant ssh master-node -c "kubectl get nodes"
   ```

3. **호스트에서 kubectl 사용**

   ```bash
   mkdir -p ~/.kube
   cp ./configs/config ~/.kube/config
   kubectl get nodes
   ```

---

## 🧪 헬스 체크

1. **노드 확인**

   ```bash
   kubectl get nodes
   ```

2. **MetalLB 파드 상태**

   ```bash
   kubectl -n metallb-system get pods
   ```

3. **Ingress Controller 확인**

   ```bash
   kubectl -n ingress-nginx get svc ingress-nginx-controller
   # EXTERNAL-IP 이 10.10.10.200~250 범위로 할당되어야 함
   ```

---

## 🛑 종료/재실행

```bash
vagrant halt       # 종료
vagrant destroy -f # 삭제
vagrant up         # 다시 생성
```
