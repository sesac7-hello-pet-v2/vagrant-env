#!/bin/bash
set -e

# 1. 공유된 조인 명령어 실행
echo " Joining the cluster"
# Vagrant는 프로젝트 루트 디렉토리를 VM의 /vagrant에 자동으로 마운트합니다.
# 이를 통해 master.sh가 생성한 join.sh 파일을 읽을 수 있습니다.
bash /vagrant/configs/join.sh

echo "Worker node has joined the cluster."