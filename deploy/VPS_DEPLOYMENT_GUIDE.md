# 🚀 Инструкция по развертыванию EXCAMAD на VPS

## 📋 Предварительные требования

- VPS сервер: 83.222.19.94
- Домен: excamad.eg-holding.ru (настроена A-запись)
- ОС: Ubuntu 20.04+
- SSH доступ: приватный ключ `c:\Users\lenovo\.ssh\privete-key.ppk`

## 🔧 Шаги по развертыванию

### 1. Подключение к серверу

Есть два способа подключения:

#### Вариант 1: Через PuTTY (рекомендуется)
```bash
putty -i c:\Users\lenovo\.ssh\privete-key.ppk root@83.222.19.94
```
Или просто откройте PuTTY и загрузите сохраненную сессию.

#### Вариант 2: Через OpenSSH
Если хотите использовать командную строку Windows:
1. Откройте PuTTYgen
2. Загрузите `c:\Users\lenovo\.ssh\privete-key.ppk`
3. В меню "Conversions" выберите "Export OpenSSH key"
4. Сохраните как `private-key`
5. Подключитесь:
```bash
ssh -i c:\Users\lenovo\.ssh\private-key root@83.222.19.94
```

### 2. Подготовка директорий

```bash
# Удаление старой версии
rm -rf /opt/apps/camunda-excamad

# Создание новой директории
mkdir -p /opt/camunda-excamad
```

### 3. Клонирование репозитория

#### Вариант 1: Через HTTPS (быстрый способ)
```bash
cd /opt
git clone https://github.com/vlikhobabin/camunda-excamad.git /opt/camunda-excamad
cd /opt/camunda-excamad
```
При запросе введите ваш логин и пароль GitHub.

#### Вариант 2: Через SSH (рекомендуется для постоянной работы)
```bash
# Генерируем SSH ключ
ssh-keygen -t ed25519 -C "your_email@example.com"
# Нажимаем Enter для всех вопросов

# Показываем публичный ключ
cat ~/.ssh/id_ed25519.pub
```

Затем:
1. Копируем показанный ключ
2. Заходим на GitHub → Settings → SSH and GPG keys → New SSH key
3. Вставляем скопированный ключ

После этого клонируем репозиторий:
```bash
cd /opt
git clone git@github.com:vlikhobabin/camunda-excamad.git /opt/camunda-excamad
cd /opt/camunda-excamad
```

### 4. Настройка конфигурации пользователей

```bash
# Создание конфигурации пользователей
mkdir -p src/config
cp src/config/users.example.yaml src/config/users.yaml
```

Отредактируйте файл `src/config/users.yaml`:
```yaml
system:
  camunda:
    username: "excamad"
    password: "VXE-3uw-XE6-2kD"
    base64: "ZXhjYW1hZDpWWEUtM3V3LVhFNi0ya0Q="

users:
  - username: "admin"
    password: "admin123"
```

### 5. Установка зависимостей и сборка

```bash
npm install
npm run build
```

### 6. Настройка Nginx

Создайте/обновите файл конфигурации:
```bash
nano /etc/nginx/sites-available/excamad.eg-holding.ru
```

Содержимое файла находится в `deploy/nginx.conf`

### 7. Перезапуск Nginx

```bash
systemctl restart nginx
```

### 8. Настройка автоматического деплоя

```bash
# Установка PM2
npm install -g pm2

# Создание директории для скриптов
mkdir -p /opt/scripts

# Копирование скриптов
cp deploy/deploy.sh /opt/scripts/
cp deploy/webhook.js /opt/scripts/

# Настройка прав
chmod +x /opt/scripts/deploy.sh
chown -R www-data:www-data /opt/camunda-excamad
chmod -R 755 /opt/camunda-excamad

# Запуск webhook через PM2
pm2 start /opt/scripts/webhook.js --name excamad-webhook
pm2 save
pm2 startup
```

### 9. Настройка GitHub webhook

1. Перейдите в настройки репозитория на GitHub
2. Выберите "Webhooks" → "Add webhook"
3. Укажите:
   - Payload URL: `https://excamad.eg-holding.ru:7777/webhook`
   - Content type: `application/json`
   - Secret: укажите секрет из webhook.js
   - События: выберите "Just the push event"

## ✅ Проверка работоспособности

1. Откройте https://excamad.eg-holding.ru
2. Проверьте:
   - Работу авторизации
   - Подключение к Camunda
   - Основные функции приложения

## 🔄 Обновление приложения

После настройки webhook, приложение будет автоматически обновляться при push в master ветку.

Для ручного обновления выполните:
```bash
/opt/scripts/deploy.sh
``` 