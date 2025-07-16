# 🚀 Скрипты автоматического деплоя EXCAMAD

Данная папка содержит PowerShell скрипты для автоматической отправки конфигурационных файлов на сервер Camunda.

## 📁 Структура файлов

```
cmunda_serv/
├── nginx/
│   ├── deploy-nginx.ps1           # Скрипт деплоя nginx конфигураций
│   ├── camunda                    # Nginx конфигурация для Camunda сервера
│   ├── camunda.eg-holding.ru      # Nginx конфигурация с CORS для Camunda
│   └── excamad.eg-holding.ru      # Nginx конфигурация для EXCAMAD приложения
├── cors/
│   ├── deploy-cors.ps1            # Скрипт деплоя CORS конфигурации
│   └── web.xml                    # Camunda web.xml с CORS настройками
└── README.md                      # Данный файл
```

## 🔧 Требования

### Программное обеспечение
- **Windows PowerShell 5.1+** или **PowerShell Core 6.0+**
- **PuTTY** с утилитами `pscp` и `plink`
- Сетевой доступ к серверу: `109.172.36.204`

### Настройка SSH
1. Убедитесь, что у вас настроена SSH аутентификация на сервере
2. Добавьте PuTTY в переменную PATH или укажите полный путь к исполняемым файлам

### Проверка готовности
```powershell
# Проверка доступности pscp
pscp --help

# Проверка доступности plink  
plink --help

# Тест подключения к серверу
plink -batch root@109.172.36.204 "echo 'Connection test'"
```

## 📤 Деплой Nginx конфигураций

### Базовое использование
```powershell
# Переход в папку nginx
cd cmunda_serv\nginx

# Простой деплой всех файлов
.\deploy-nginx.ps1

# Деплой с включением сайтов
.\deploy-nginx.ps1 -EnableSites

# Режим тестирования (без отправки файлов)
.\deploy-nginx.ps1 -DryRun
```

### Расширенные опции
```powershell
# Деплой на другой сервер
.\deploy-nginx.ps1 -ServerIP "192.168.1.100"

# Указание другого пользователя
.\deploy-nginx.ps1 -Username "admin"

# Указание другого пути
.\deploy-nginx.ps1 -RemotePath "/etc/nginx/conf.d"

# Комбинированный запуск
.\deploy-nginx.ps1 -EnableSites -DryRun
```

### Что делает скрипт
1. ✅ Проверяет наличие всех nginx файлов
2. 📤 Отправляет файлы на сервер
3. 🔗 Включает сайты (при указании -EnableSites)
4. 🔍 Тестирует nginx конфигурацию
5. 🔄 Перезагружает nginx

## 📋 Деплой CORS конфигурации

### Базовое использование
```powershell
# Переход в папку cors
cd cmunda_serv\cors

# Простой деплой с бэкапом
.\deploy-cors.ps1

# Деплой с перезапуском Tomcat
.\deploy-cors.ps1 -RestartTomcat

# Режим тестирования
.\deploy-cors.ps1 -DryRun
```

### Расширенные опции
```powershell
# Деплой без создания бэкапа
.\deploy-cors.ps1 -CreateBackup:$false

# Указание другого пути для бэкапов
.\deploy-cors.ps1 -BackupPath "/home/backups"

# Деплой на другой сервер с перезапуском
.\deploy-cors.ps1 -ServerIP "192.168.1.100" -RestartTomcat

# Указание другого пути к Tomcat
.\deploy-cors.ps1 -RemotePath "/opt/tomcat/webapps/engine-rest/WEB-INF"
```

### Что делает скрипт
1. ✅ Проверяет валидность XML файла
2. 💾 Создает бэкап текущего файла
3. 📤 Отправляет новый web.xml
4. 🔐 Устанавливает правильные права доступа
5. 🔄 Перезапускает Tomcat (при указании -RestartTomcat)

## 🛠️ Устранение неполадок

### Ошибка "pscp не найден"
```powershell
# Добавьте PuTTY в PATH или используйте полный путь
$env:PATH += ";C:\Program Files\PuTTY"

# Или скачайте PuTTY с официального сайта
# https://www.putty.org/
```

### Ошибка SSH подключения
```powershell
# Проверьте подключение вручную
plink root@109.172.36.204

# Убедитесь, что SSH ключи настроены
# или используйте пароль
```

### Ошибка прав доступа
```powershell
# Запустите PowerShell от имени администратора
# или проверьте права на файлы
```

### Проблемы с Tomcat
```powershell
# Проверьте статус Tomcat на сервере
plink root@109.172.36.204 "systemctl status tomcat9"

# Просмотр логов Tomcat
plink root@109.172.36.204 "tail -f /opt/camunda7/server/apache-tomcat-10.1.36/logs/catalina.out"
```

## 📊 Мониторинг и логи

### Просмотр логов nginx
```powershell
# Логи доступа
plink root@109.172.36.204 "tail -f /var/log/nginx/access.log"

# Логи ошибок
plink root@109.172.36.204 "tail -f /var/log/nginx/error.log"

# Логи конкретного сайта
plink root@109.172.36.204 "tail -f /var/log/nginx/excamad.access.log"
```

### Проверка статуса сервисов
```powershell
# Статус nginx
plink root@109.172.36.204 "systemctl status nginx"

# Статус Tomcat
plink root@109.172.36.204 "systemctl status tomcat9"

# Проверка открытых портов
plink root@109.172.36.204 "netstat -tlnp | grep -E '(80|443|8080)'"
```

## 🔄 Восстановление из бэкапа

### Восстановление nginx конфигурации
```powershell
# Отключение сайта
plink root@109.172.36.204 "rm /etc/nginx/sites-enabled/excamad.eg-holding.ru"

# Восстановление из git
plink root@109.172.36.204 "cd /etc/nginx/sites-available && git checkout HEAD -- excamad.eg-holding.ru"
```

### Восстановление CORS конфигурации
```powershell
# Просмотр доступных бэкапов
plink root@109.172.36.204 "ls -la /opt/camunda7/backups/"

# Восстановление конкретного бэкапа (замените TIMESTAMP)
plink root@109.172.36.204 "cp /opt/camunda7/backups/web.xml.backup.TIMESTAMP /opt/camunda7/server/apache-tomcat-10.1.36/webapps/engine-rest/WEB-INF/web.xml"

# Перезапуск Tomcat
plink root@109.172.36.204 "systemctl restart tomcat9"
```

## 📋 Чеклист перед деплоем

### Nginx
- [ ] Проверены все конфигурационные файлы
- [ ] Убедитесь в корректности доменных имен
- [ ] Проверены SSL сертификаты
- [ ] Протестирована конфигурация локально

### CORS
- [ ] Проверена валидность XML
- [ ] Убедитесь в корректности CORS настроек
- [ ] Проверен список разрешенных доменов
- [ ] Создан бэкап текущей конфигурации

## 🚨 Важные замечания

1. **Всегда используйте -DryRun** для тестирования перед реальным деплоем
2. **Создавайте бэкапы** перед изменением production конфигураций
3. **Проверяйте логи** после деплоя для убедиться в корректной работе
4. **Тестируйте CORS** настройки с фронтенд приложением
5. **Мониторьте производительность** после изменений

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи скриптов и сервисов
2. Убедитесь в доступности сервера
3. Проверьте права доступа к файлам
4. Используйте режим -DryRun для диагностики

---

**Удачного деплоя! 🚀** 