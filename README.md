# Vagrant를 이용한 Kubernetes 클러스터 환경

Vagrant를 사용하여 로컬 환경에 Kubernetes 클러스터를 구성합니다. 이 환경은 1개의 마스터 노드와 2개의 워커 노드로 이루어져 있습니다.

## 사전 준비 사항

1.  **[Vagrant](https://www.vagrantup.com/downloads) 설치**

    *   **Debian/Ubuntu (WSL)의 경우:** 아래 명령어를 사용하여 설치할 수 있습니다.
        ```bash
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
        sudo apt-get update && sudo apt-get install vagrant
        ```
    *   다른 운영체제의 경우 공식 홈페이지의 다운로드 링크를 이용해주세요.

2.  **[VirtualBox](https://www.virtualbox.org/wiki/Downloads) 설치**

3.  **WSL (Windows Subsystem for Linux) 사용**
    *   Vagrant와 VirtualBox는 Windows 호스트에 설치해야 합니다.
    *   모든 Vagrant 명령어는 WSL 터미널 내에서 실행합니다.

## 권장 Vagrant 플러그인

WSL2 환경에서 Vagrant가 Windows에 설치된 VirtualBox를 제어하기 위해 다음 플러그인 설치를 권장합니다.

```bash
vagrant plugin install virtualbox_WSL2
```

## WSL 사용 시 참고사항

WSL 환경에서 Vagrant를 사용하려면, WSL의 Vagrant가 Windows의 VirtualBox를 제어할 수 있도록 몇 가지 설정이 필요합니다. `.bashrc` 또는 `.zshrc` 같은 쉘 설정 파일에 아래 내용을 추가하는 것을 권장합니다.

1.  **Windows 기능 접근 활성화**

    ```bash
    export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
    ```

2.  **VirtualBox 경로 추가** (VirtualBox 설치 경로에 맞게 수정)

    ```bash
    export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
    ```

    설정 파일을 수정한 후에는 `source ~/.bashrc` 명령어를 실행하거나 터미널을 재시작하여 변경사항을 적용해주세요.

## 실행 방법

1.  **Vagrant 환경 실행**

    WSL 터미널에서 `vagrant-env` 디렉토리로 이동한 후, 다음 명령어를 실행하여 모든 가상 머신(마스터, 워커)을 생성하고 프로비저닝합니다.

    ```bash
    vagrant up
    ```

2.  **Kubernetes 클러스터 접속**

    프로비저닝이 완료되면 `master-node`의 `~/.kube/config` 파일이 호스트 머신(Vagrant를 실행한 위치)의 `./configs/config` 파일로 복사됩니다. `kubectl`을 사용하여 클러스터를 관리할 수 있습니다.

    마스터 노드에 직접 SSH로 접속하려면 다음 명령어를 사용하세요.

    ```bash
    vagrant ssh master-node
    ```

3.  **클러스터 상태 확인**

    마스터 노드에 접속한 후, 다음 명령어로 클러스터의 노드 상태를 확인할 수 있습니다.

    ```bash
    kubectl get nodes
    ```

## 가상 머신(VM) 관리 명령어

-   `vagrant status`: VM의 현재 상태(running, saved, poweroff)를 확인합니다.
-   `vagrant halt`: 실행 중인 모든 VM을 정상적으로 종료합니다.
-   `vagrant destroy -f`: 모든 VM을 영구적으로 삭제합니다. **(주의: 되돌릴 수 없습니다.)**

## 디렉토리 구조

-   `Vagrantfile`: Vagrant의 설정 파일. VM의 종류, 네트워크, 프로비저닝 방법 등을 정의합니다.
-   `scripts/`: VM 프로비저닝에 사용되는 쉘 스크립트들이 위치합니다.
-   `configs/`: Kubernetes 클러스터 접속을 위한 `config` 파일이 저장되는 위치입니다.
