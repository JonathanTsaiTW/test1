# 使用輕量級的 Nginx Alpine 映像
FROM nginx:alpine

# 維護者資訊
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
LABEL org.opencontainers.image.description="井字遊戲 - 靜態網頁應用"
LABEL org.opencontainers.image.licenses="MIT"

# 移除預設的 Nginx 網頁
RUN rm -rf /usr/share/nginx/html/*

# 複製靜態檔案到 Nginx 目錄
COPY app/ /usr/share/nginx/html/

# 建立自訂的 Nginx 配置（監聽 8080 端口以支援非 root 用戶）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 修改 Nginx 配置以支援非 root 用戶運行
RUN sed -i 's/listen\s*80;/listen 8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i '/user\s*nginx;/d' /etc/nginx/nginx.conf && \
    sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf && \
    sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf

# 暴露 8080 端口（非特權端口）
EXPOSE 8080

# 建立並切換到非 root 使用者以改善容器安全
# 使用 UID/GID 1000，並確保 Nginx 可寫入所需的暫存目錄
RUN addgroup -g 1000 app || addgroup app && \
    adduser -D -u 1000 -G app app || adduser -D -G app app && \
    mkdir -p /tmp/proxy_temp /tmp/client_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp /var/cache/nginx && \
    chown -R app:app /usr/share/nginx/html /tmp /var/cache/nginx || true

# 切換到非 root 使用者（容器內的進程將以此使用者執行）
USER app

# 啟動 Nginx
CMD ["nginx", "-g", "daemon off;"]