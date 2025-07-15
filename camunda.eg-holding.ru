server {
    listen 80;
    server_name camunda.eg-holding.ru;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name camunda.eg-holding.ru;

    ssl_certificate /etc/letsencrypt/live/camunda.eg-holding.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/camunda.eg-holding.ru/privkey.pem;

    location / {
        # Обработка pre-flight запросов OPTIONS
        if ($request_method = 'OPTIONS') {
           add_header 'Access-Control-Allow-Origin' '*' always;
           add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
           add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, X-Requested-With' always;
           add_header 'Access-Control-Max-Age' 1728000;
           add_header 'Content-Type' 'text/plain charset=UTF-8';
           add_header 'Content-Length' 0;
           return 204;
        }

        # Добавляем CORS заголовки для всех остальных (не-OPTIONS) запросов
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, X-Requested-With' always;

        # Проксируем запрос на Tomcat
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}