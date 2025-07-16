# HTTP → HTTPS редирект
server {
    listen 80;
    server_name excamad.eg-holding.ru;
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер для EXCAMAD приложения
server {
    listen 443 ssl http2;
    server_name excamad.eg-holding.ru;

    # SSL сертификаты (нужно будет получить отдельные или wildcard)
    ssl_certificate /etc/letsencrypt/live/excamad.eg-holding.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/excamad.eg-holding.ru/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Корневая директория для статических файлов
    root /var/www/excamad/dist;
    index index.html;

    # Настройки безопасности
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'" always;

    # Основная локация для SPA
    location / {
        try_files $uri $uri/ /index.html;
        
        # Настройки кеширования для статических файлов
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Прокси для API запросов к Camunda (если нужно)
    location /camunda-api/ {
        proxy_pass https://camunda.eg-holding.ru/;
        proxy_set_header Host camunda.eg-holding.ru;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Логи
    access_log /var/log/nginx/excamad.access.log;
    error_log /var/log/nginx/excamad.error.log;
} 