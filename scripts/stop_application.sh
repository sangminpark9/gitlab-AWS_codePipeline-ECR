#!/bin/bash
set +e  # 에러 무시

CONTAINER_NAME="my-nginx-container"

# 컨테이너 중지 및 삭제
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

