# 🚀 Инструкция по развертыванию EXCAMAD на VPS

## 📋 Предварительные требования

- VPS сервер: 83.222.19.94
- Домен: excamad.eg-holding.ru (настроена A-запись)
- ОС: Ubuntu 20.04+ или CentOS 7+
- Права: root или sudo

## 🔧 1. Подготовка сервера

### Установка необходимого ПО

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Node.js (версия 16+)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Установка Nginx
sudo apt install nginx -y

# Установка PM2 для управления процессами
sudo npm install -g pm2

# Установка Git
sudo apt install git -y

# Установка Certbot для SSL
sudo apt install certbot python3-certbot-nginx -y
```

### Настройка пользователя для приложения

```bash
# Создание пользователя
sudo adduser excamad
sudo usermod -aG sudo excamad

# Переключение на пользователя
sudo su - excamad
```

## 🗂️ 2. Клонирование и настройка проекта

### Клонирование репозитория

```bash
# Переход в домашнюю директорию
cd /home/excamad

# Клонирование проекта
git clone https://github.com/YOUR_USERNAME/excamad.git
cd excamad

# Установка зависимостей
npm install
```

### Настройка переменных окружения

```bash
# Создание файла окружения
cp .env.example .env

# Редактирование настроек
nano .env
```

Содержимое `.env`:
```env
VUE_APP_CAMUNDA_BASE_URL=https://camunda.eg-holding.ru/engine-rest/
VUE_APP_CAMUNDA_AUTH_URL=https://camunda.eg-holding.ru/engine-rest/identity/verify
VUE_APP_BPMAS_URL=http://cloud-dev.bpmn2.ru/bpmas/rest
NODE_ENV=production
```

### Сборка проекта

```bash
# Сборка продакшн версии
npm run build

# Создание директории для веб-файлов
sudo mkdir -p /var/www/excamad
sudo chown excamad:excamad /var/www/excamad

# Копирование собранных файлов
cp -r dist/* /var/www/excamad/
```

## 🌐 3. Настройка Nginx

### Создание конфигурации сайта

```bash
sudo nano /etc/nginx/sites-available/excamad.eg-holding.ru
```

Вставить конфигурацию из файла `cmunda_serv/nginx/excamad.eg-holding.ru`

### Активация сайта

```bash
# Создание символической ссылки
sudo ln -s /etc/nginx/sites-available/excamad.eg-holding.ru /etc/nginx/sites-enabled/

# Проверка конфигурации
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

## 🔒 4. Настройка SSL

### Получение SSL сертификата

```bash
# Получение сертификата Let's Encrypt
sudo certbot --nginx -d excamad.eg-holding.ru

# Проверка автообновления
sudo certbot renew --dry-run
```

## 🔄 5. Настройка автоматического обновления

### Создание скрипта деплоя

```bash
nano /home/excamad/deploy.sh
```

Содержимое скрипта:
```bash
#!/bin/bash

# Переход в директорию проекта
cd /home/excamad/excamad

# Остановка PM2 процесса (если используется)
# pm2 stop excamad || true

# Резервное копирование текущей версии
sudo cp -r /var/www/excamad /var/www/excamad.backup.$(date +%Y%m%d_%H%M%S)

# Получение последних изменений
git pull origin master

# Установка новых зависимостей
npm install

# Сборка проекта
npm run build

# Копирование новых файлов
sudo cp -r dist/* /var/www/excamad/

# Перезапуск Nginx
sudo systemctl reload nginx

# Очистка старых бэкапов (старше 7 дней)
sudo find /var/www/excamad.backup.* -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo "Деплой завершен: $(date)"
```

### Настройка прав на выполнение

```bash
chmod +x /home/excamad/deploy.sh
```

### Создание webhook для GitHub (опционально)

```bash
# Установка Node.js сервера для webhook
npm install -g github-webhook-handler

# Создание скрипта webhook
nano /home/excamad/webhook.js
```

Содержимое webhook.js:
```javascript
const http = require('http');
const createHandler = require('github-webhook-handler');
const { exec } = require('child_process');

const handler = createHandler({ path: '/webhook', secret: 'YOUR_WEBHOOK_SECRET' });

http.createServer((req, res) => {
  handler(req, res, (err) => {
    res.statusCode = 404;
    res.end('no such location');
  });
}).listen(7777);

handler.on('error', (err) => {
  console.error('Error:', err.message);
});

handler.on('push', (event) => {
  console.log('Received a push event for %s to %s',
    event.payload.repository.name,
    event.payload.ref);
    
  if (event.payload.ref === 'refs/heads/master') {
    exec('/home/excamad/deploy.sh', (error, stdout, stderr) => {
      if (error) {
        console.error(`Deploy error: ${error}`);
        return;
      }
      console.log(`Deploy output: ${stdout}`);
    });
  }
});

handler.on('issues', (event) => {
  console.log('Received an issues event for %s action=%s: #%d %s',
    event.payload.repository.name,
    event.payload.action,
    event.payload.issue.number,
    event.payload.issue.title);
});

console.log('Webhook server listening on port 7777');
```

### Запуск webhook через PM2

```bash
# Запуск webhook сервера
pm2 start /home/excamad/webhook.js --name excamad-webhook

# Сохранение конфигурации PM2
pm2 save
pm2 startup
```

## 📊 6. Мониторинг и логи

### Просмотр логов

```bash
# Логи Nginx
sudo tail -f /var/log/nginx/excamad.access.log
sudo tail -f /var/log/nginx/excamad.error.log

# Логи PM2 (если используется)
pm2 logs excamad-webhook
```

### Проверка статуса

```bash
# Статус Nginx
sudo systemctl status nginx

# Статус PM2
pm2 status

# Проверка SSL сертификата
sudo certbot certificates
```

## 🔧 7. Обслуживание

### Ручное обновление

```bash
# Выполнение деплоя
/home/excamad/deploy.sh
```

### Откат к предыдущей версии

```bash
# Найти последний бэкап
ls -la /var/www/excamad.backup.*

# Восстановление (замените TIMESTAMP)
sudo rm -rf /var/www/excamad/*
sudo cp -r /var/www/excamad.backup.TIMESTAMP/* /var/www/excamad/
sudo systemctl reload nginx
```

### Настройка cron для автоматических обновлений

```bash
# Добавление задания в cron (обновление каждый день в 3:00)
crontab -e

# Добавить строку:
0 3 * * * /home/excamad/deploy.sh >> /home/excamad/deploy.log 2>&1
```

## 🛡️ 8. Безопасность

### Настройка файервола

```bash
# Установка ufw
sudo apt install ufw -y

# Разрешение необходимых портов
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 7777  # для webhook

# Включение файервола
sudo ufw enable
```

### Настройка автоматических обновлений безопасности

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

## ✅ 9. Проверка работоспособности

1. Откройте https://excamad.eg-holding.ru
2. Проверьте подключение к Camunda
3. Протестируйте основные функции
4. Проверьте работу автоматического обновления

## 📞 10. Поддержка

При возникновении проблем:
1. Проверьте логи Nginx и PM2
2. Убедитесь в корректности DNS записей
3. Проверьте статус SSL сертификата
4. Протестируйте подключение к Camunda серверу

---

**Важно:** Сохраните все пароли и секретные ключи в безопасном месте!