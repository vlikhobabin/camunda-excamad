#!/bin/bash

# EXCAMAD Deployment Script
# This script automates the deployment process on VPS

echo "🚀 Starting EXCAMAD deployment..."

# Переход в директорию проекта
cd /home/excamad/excamad

# Остановка PM2 процесса (если используется)
# pm2 stop excamad || true

# Резервное копирование текущей версии
echo "📦 Creating backup..."
sudo cp -r /var/www/excamad /var/www/excamad.backup.$(date +%Y%m%d_%H%M%S)

# Получение последних изменений
echo "⬇️ Pulling latest changes from GitHub..."
git pull origin master

# Установка новых зависимостей
echo "📦 Installing dependencies..."
npm install

# Сборка проекта
echo "🔨 Building project..."
npm run build

# Копирование новых файлов
echo "📂 Copying files to web directory..."
sudo cp -r dist/* /var/www/excamad/

# Перезапуск Nginx
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

# Очистка старых бэкапов (старше 7 дней)
echo "🧹 Cleaning old backups..."
sudo find /var/www/excamad.backup.* -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo "✅ Деплой завершен: $(date)"
echo "🌐 Приложение доступно по адресу: https://excamad.eg-holding.ru" 