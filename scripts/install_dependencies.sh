#!/bin/bash
set -e

# Docker 설치 여부 확인 및 설치
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing..."
  sudo yum update -y
  sudo yum install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker ec2-user
else
  echo "Docker already installed."
  
fi
