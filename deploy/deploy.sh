#!/bin/bash

# EXCAMAD Deployment Script
# This script automates the deployment process on VPS

echo "🚀 Starting EXCAMAD deployment..."

# Переход в директорию проекта
cd /opt/camunda-excamad

# Сохраняем текущие настройки
cp src/config/users.yaml /tmp/users.yaml.backup

# Получение последних изменений
echo "⬇️ Pulling latest changes from GitHub..."
git pull origin master

# Восстанавливаем настройки
cp /tmp/users.yaml.backup src/config/users.yaml
rm /tmp/users.yaml.backup

# Установка новых зависимостей
echo "📦 Installing dependencies..."
npm install

# Сборка проекта
echo "🔨 Building project..."
npm run build

# Перезапуск Nginx
echo "🔄 Reloading Nginx..."
systemctl reload nginx

echo "✅ Деплой завершен: $(date)"
echo "🌐 Приложение доступно по адресу: https://excamad.eg-holding.ru" 