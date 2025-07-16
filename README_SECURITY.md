# Комплексный аудит безопасности проекта. 

## 🔴 КРИТИЧЕСКИЕ ПРОБЛЕМЫ БЕЗОПАСНОСТИ

### 1. **Захардкоженные URL-адреса организации**
**Расположение:** `src/config/settings.js`, `src/config/camundasUrl.js`
```javascript
// Содержат конкретные URL вашей организации
"https://camunda.eg-holding.ru/engine-rest/identity/verify"
'https://camunda.eg-holding.ru/engine-rest/'
```
**🚨 ДЕЙСТВИЕ:** Перед публикацией замените на переменные окружения или примеры.

### 2. **Дефолтные учетные данные в коде**
**Расположение:** `src/store/store.js` (строка 52)
```javascript
var obj = {
  url: 'http://bpm.tinkoff.ru',
  type: "BASIC/JWT", 
  login: "login",
  password: "password",
  JWT: "JWergergT"
}
```
**🚨 ДЕЙСТВИЕ:** Удалить эти тестовые данные.

### 3. **Ошибка в коде безопасности**
**Расположение:** `src/config/groupRoles.js` (строка 18)
```javascript
if (defaultSuperAdminLogins.indexOf(login) != -1) {
```
**🚨 ПРОБЛЕМА:** Переменная `defaultSuperAdminLogins` используется, но не определена. Это может вызвать ошибки в системе проверки ролей.

## 🟡 СРЕДНИЕ ПРОБЛЕМЫ БЕЗОПАСНОСТИ

### 4. **Хранение токенов в localStorage**
Приложение сохраняет токены аутентификации в `localStorage`:
```javascript
localStorage.setItem('usertoken', token);
```
**⚠️ РЕКОМЕНДАЦИЯ:** Рассмотрите использование более безопасных методов хранения (httpOnly cookies).

### 5. **Пустые URL-адреса для интеграций**
В `settings.js` много пустых строк для интеграций:
```javascript
export const BITBUCKETURL = ""; 
export const JIRAPATH = "";
```
**✅ СТАТУС:** Безопасно для публикации.

## 🟢 ПОЛОЖИТЕЛЬНЫЕ АСПЕКТЫ

### 6. **Корректный .gitignore**
Файл `.gitignore` правильно исключает:
- `.env` файлы
- `node_modules`
- Логи и временные файлы

### 7. **Отсутствие API ключей**
В коде не найдены:
- API ключи
- Секретные токены
- Пароли пользователей
- Ключи шифрования

## 📋 ЧЕКЛИСТ ПЕРЕД ПУБЛИКАЦИЕЙ

### ✅ ОБЯЗАТЕЛЬНЫЕ ДЕЙСТВИЯ:

1. **Замените URL-адреса организации:**
   ```javascript
   // Вместо:
   export const URLFORAUTH = "https://camunda.eg-holding.ru/engine-rest/identity/verify";
   
   // Используйте:
   export const URLFORAUTH = process.env.VUE_APP_CAMUNDA_AUTH_URL || "https://your-camunda-instance.example.com/engine-rest/identity/verify";
   ```

2. **Удалите тестовые данные из store.js:**
   ```javascript
   // Удалить или заменить объект obj на строке 45-55
   ```

3. **Исправьте ошибку с defaultSuperAdminLogins:**
   ```javascript
   // В groupRoles.js добавьте:
   const defaultSuperAdminLogins = []; // или определите список администраторов
   ```

4. **Создайте файл .env.example:**
   ```env
   VUE_APP_CAMUNDA_AUTH_URL=https://your-camunda-instance.example.com/engine-rest/identity/verify
   VUE_APP_CAMUNDA_BASE_URL=https://your-camunda-instance.example.com/engine-rest/
   ```

### 🔧 РЕКОМЕНДУЕМЫЕ ДЕЙСТВИЯ:

1. **Добавьте документацию по безопасности в README**
2. **Рассмотрите использование HTTPS для всех соединений**
3. **Добавьте валидацию входных данных на клиенте**

## 🎯 ЗАКЛЮЧЕНИЕ

Ваш проект в целом безопасен для публикации, но **необходимо выполнить критические исправления** перед размещением на GitHub. Основные риски связаны с раскрытием URL-адресов вашей организации и наличием тестовых данных в коде.

## 🎯 ПОДХОДЫ К РЕШЕНИЮ

### 📁 **Подход 1: Переменные окружения (РЕКОМЕНДУЕМЫЙ)**

**Преимущества:**
- Максимальная безопасность
- Легкое развертывание в разных средах
- Стандартная практика для Vue.js приложений

**Шаги реализации:**

1. **Создайте файл `.env.example` в корне проекта:**
```env
# Camunda Configuration
VUE_APP_CAMUNDA_BASE_URL=https://your-camunda-instance.example.com/engine-rest/
VUE_APP_CAMUNDA_AUTH_URL=https://your-camunda-instance.example.com/engine-rest/identity/verify
VUE_APP_BPMAS_URL=https://your-bpmas-instance.example.com/bpmas/rest

# Development URLs (optional)
VUE_APP_CAMUNDA_DEV_URL=http://localhost:8080/engine-rest/
```

2. **Создайте файл `.env` для локальной разработки:**
```env
VUE_APP_CAMUNDA_BASE_URL=https://camunda.eg-holding.ru/engine-rest/
VUE_APP_CAMUNDA_AUTH_URL=https://camunda.eg-holding.ru/engine-rest/identity/verify
VUE_APP_BPMAS_URL=http://cloud-dev.bpmn2.ru/bpmas/rest
```

3. **Обновите `src/config/settings.js`:**
```javascript
export const BPMAASURL = 
  process.env.VUE_APP_BPMAS_URL || "http://localhost:8080/bpmas/rest";

export const STATRTERPROCESSNAME = "StarterProcess";

export const PRODSUBSTRING = "cloud";
export const TESTSUBSTRING = "test";

export const PREFIXURLINPATHTOREMOVE = "http://cloud";
export const POSTFIXURLINPATHTOREMOVE = "bpmn2.ru";

export const REVERSPROXYURL = "/camunda-excamad/proxy/";

export const SERVERVIRTALPATHPROD = "/camunda-excamad/";

export const BITBUCKETURL = process.env.VUE_APP_BITBUCKET_URL || "";

export const JIRAPATH = process.env.VUE_APP_JIRA_URL || "";

export const TESTSPLUNKURL = process.env.VUE_APP_SPLUNK_TEST_URL || "";
export const PRODSPLUNKURL = process.env.VUE_APP_SPLUNK_PROD_URL || "";

export const TESTAUDITURL = process.env.VUE_APP_AUDIT_TEST_URL || "";
export const PRODAUDITURL = process.env.VUE_APP_AUDIT_PROD_URL || "";

export const USERPHOTOLOADURL = process.env.VUE_APP_USER_PHOTO_URL || "";

export const URLFORAUTH = 
  process.env.VUE_APP_CAMUNDA_AUTH_URL || 
  "https://example.com/engine-rest/identity/verify";
```

4. **Обновите `src/config/camundasUrl.js`:**
```javascript
export function generatePossibleUrl() {
  // Получаем базовый URL из переменных окружения
  const defaultUrl = process.env.VUE_APP_CAMUNDA_BASE_URL || 
                    'https://example.com/engine-rest/';
  
  // Список возможных URL начинается с конфигурационного
  const arrayOfPossibleUlr = [defaultUrl];

  // Добавляем дополнительные URL из development режима
  if (process.env.NODE_ENV === 'development' && process.env.VUE_APP_CAMUNDA_DEV_URL) {
    arrayOfPossibleUlr.push(process.env.VUE_APP_CAMUNDA_DEV_URL);
  }

  // Добавляем URL из localStorage (пользовательские настройки)
  if (localStorage.listOfUrl) {
    const list = JSON.parse(localStorage.listOfUrl);
    list.forEach(item => {
      if (arrayOfPossibleUlr.indexOf(item) === -1) {
        arrayOfPossibleUlr.push(item);
      }
    });
  }

  return arrayOfPossibleUlr;
}
```

5. **Обновите `.gitignore`:**
```gitignore
# Existing content...

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Keep example file
!.env.example
```