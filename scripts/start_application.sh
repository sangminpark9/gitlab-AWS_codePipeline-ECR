#!/bin/bash
set -e

# 변수 설정
IMAGE_URI="476114142897.dkr.ecr.ap-northeast-2.amazonaws.com/nginx-app:latest"
CONTAINER_NAME="my-nginx-container"

# AWS ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $(echo "$IMAGE_URI" | cut -d'/' -f1)


# 이미지 풀
docker pull "$IMAGE_URI"

# 컨테이너 실행 (기존 컨테이너 존재시 제거는 stop에서 수행)
docker run -d --name "$CONTAINER_NAME" -p 80:80 "$IMAGE_URI"
