# gitlab-AWS_codePipeline-ECR
gitlab+AWS_codePipeline+ECR

![image](https://github.com/user-attachments/assets/555507b7-47a0-4b7b-94a1-3655b8650b6f)


---

````markdown
# 🚀 GitLab Self-managed + AWS CI/CD 파이프라인 구축

이 프로젝트는 GitLab Self-managed 환경에서 AWS 서비스를 활용한 CI/CD 파이프라인 구축 사례를 다룹니다.

## 🎯 목표

- **소스**: GitLab Self-managed (nginx 웹 서버)
- **빌드**: AWS CodeBuild (Docker 이미지 빌드 → ECR 푸시)
- **배포**: AWS CodeDeploy (EC2 인스턴스에 컨테이너 배포)
- **트리거**: `main` 브랜치에 머지 시 자동 배포

## 🏗️ 아키텍처

```mermaid
graph TD;
    GitLab -->|Webhook| CodePipeline
    CodePipeline --> CodeBuild
    CodeBuild -->|Docker Push| ECR
    CodePipeline --> CodeDeploy
    CodeDeploy --> EC2
````

## ⚙️ 구성 요소

* `buildspec.yml`
  CodeBuild 단계에서 Docker 이미지를 빌드하고 ECR에 푸시

* `appspec.yml`, `*.sh` 스크립트
  CodeDeploy 단계에서 EC2에 컨테이너를 배포

## 🐛 문제 해결 경험

### 1. GitLab 연결 (Webhook)

* **문제**: VPC 환경에서 GitLab Self-managed 연결 실패
* **해결**: `ngrok` 사용 → Webhook 수신 가능
* **주의**: CodePipeline 연결 시 "No VPC" 옵션 선택 필요

### 2. SSH 키 문제

* **문제**: EC2와 GitLab의 키 불일치로 인한 `Permission denied`
* **해결**: PEM 키에서 공개키 추출하여 GitLab 등록

### 3. buildspec 길이 제한

* **문제**: 인라인 입력 시 1000자 제한
* **해결**: GitLab 저장소에 `buildspec.yml` 직접 생성

### 4. IAM 권한 부족

* **문제**: CodePipeline과 CodeBuild에 필요한 권한 부족
* **해결**: 테스트 환경에서는 넓은 권한(`Action: *`)으로 임시 허용

### 5. CodeDeploy 설정

* **주의**: EC2 인스턴스에 `Name` 태그가 정확히 일치해야 배포 가능

## 🧪 브랜치 전략

```bash
# 개발
git checkout dev
# 코드 작업...
git push origin dev

# 배포
git checkout main
git merge dev
git push origin main  # CodePipeline 자동 트리거
```

## ✅ 현재 상태

* [x] GitLab → CodePipeline 연동
* [x] Docker 이미지 빌드 및 ECR 푸시
* [x] EC2에서 컨테이너 실행 확인
* [ ] 모니터링 및 롤백 전략 적용 예정

## 📌 교훈 및 팁

* IAM 권한 문제는 대부분의 에러 원인 → 테스트 환경에서는 권한을 넓게 설정
* 환경 변수는 "텍스트" 타입이 가장 안정적
* `appspec.yml`과 `buildspec.yml`은 **파일로** 관리하는 것이 유지보수에 유리
* EC2 태그 매칭은 CodeDeploy의 핵심 → 정확한 키-값 입력 필요

## 🔧 향후 계획

* [ ] CloudWatch 로그 및 SNS 알림 구성
* [ ] Docker 컨테이너 헬스체크/재시작 자동화
* [ ] 롤백 조건 설정

---

🙌 본 프로젝트는 AWS 인프라 자동화에 익숙해지기 위한 실습 목적입니다. 테스트 목적의 권한 설정은 실제 운영 환경에서 반드시 최소 권한으로 변경하세요.

---

추가 설명

* `buildspec.yml`: **구성 요소** 섹션에 구체적인 설명 및 예시 포함
* `appspec.yml`: **CodeDeploy 설정** 및 **배포 구성**으로 별도 하위 섹션 추가

---

````markdown
## ⚙️ 구성 요소

### 📄 buildspec.yml

AWS CodeBuild에서 Docker 이미지를 빌드하고 ECR로 푸시하는 데 사용됩니다.  
이 파일은 GitLab 리포지토리 루트에 위치해야 하며 다음과 같이 구성합니다:

```yaml
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: ap-northeast-2
    AWS_ACCOUNT_ID: xxxxxxxxxxxx
    IMAGE_REPO_NAME: nginx-app
    IMAGE_TAG: latest

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - printf '[{"name":"nginx-container","imageUri":"%s"}]' $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
    - appspec.yml
````

* `imagedefinitions.json`: CodeDeploy에 전달할 이미지 정보
* `appspec.yml`: 배포 시 사용될 스크립트 및 컨테이너 정의 포함

---

## 🚀 배포 구성: appspec.yml

CodeDeploy는 이 파일을 통해 EC2에서 컨테이너를 어떻게 실행할지 제어합니다.
`imagedefinitions.json`과 함께 사용되며 다음과 같은 형태로 작성됩니다:

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Container
      Properties:
        TaskDefinition: null
        LoadBalancerInfo:
          ContainerName: "nginx-container"
          ContainerPort: 80
Hooks:
  BeforeInstall:
    - location: scripts/stop.sh
      timeout: 180
      runas: root
  AfterInstall:
    - location: scripts/start.sh
      timeout: 180
      runas: root
  ApplicationStart:
    - location: scripts/health-check.sh
      timeout: 180
      runas: root
```

* **Hooks 설명**:

  * `BeforeInstall`: 기존 컨테이너 중지
  * `AfterInstall`: 새로운 컨테이너 실행
  * `ApplicationStart`: 헬스 체크 수행

### 🔧 예시 스크립트 (`scripts/stop.sh` 등)

```bash
#!/bin/bash
docker stop my-nginx-container || true
docker rm my-nginx-container || true
```

```bash
#!/bin/bash
docker run -d --name my-nginx-container -p 80:80 \
  476114142897.dkr.ecr.ap-northeast-2.amazonaws.com/nginx-app:latest
```

```bash
#!/bin/bash
curl -f http://localhost/health || exit 1
```

> 모든 스크립트는 `scripts/` 디렉토리에 위치해야 하며 실행 권한을 부여해야 합니다 (`chmod +x`).

---


