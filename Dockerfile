FROM nginx:alpine

# 커스텀 nginx 설정 복사
COPY nginx.conf /etc/nginx/nginx.conf

# 정적 파일 복사
COPY html/ /usr/share/nginx/html/

# 포트 노출
EXPOSE 80

# nginx 실행
CMD ["nginx", "-g", "daemon off;"]