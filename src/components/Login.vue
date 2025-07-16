<template>
  <div class="login-component">
    <!-- Форма входа -->
    <div v-if="!isAuthenticated" class="login-form">
      <form @submit.prevent="login">
        <h3>Вход в систему</h3>
        
        <div class="form-group">
          <label for="username">Имя пользователя</label>
          <input
            id="username"
            v-model="formUsername"
            type="text"
            class="form-control"
            required
            placeholder="Введите имя пользователя"
          />
        </div>

        <div class="form-group">
          <label for="password">Пароль</label>
          <input
            id="password"
            v-model="password"
            type="password"
            class="form-control"
            required
            placeholder="Введите пароль"
          />
        </div>

        <div class="alert alert-danger" v-if="authStatus === 'error'">
          Неверные учетные данные
        </div>

        <button 
          type="submit" 
          class="btn btn-primary btn-block"
          :disabled="authStatus === 'loading'"
        >
          {{ authStatus === 'loading' ? 'Вход...' : 'Войти' }}
        </button>
      </form>
    </div>

    <!-- Информация о пользователе в навбаре -->
    <div v-else class="nav-user-info">
      <b-nav-item-dropdown right>
        <template #button-content>
          <span class="username">{{ currentUsername }}</span>
        </template>
        <b-dropdown-item @click="logout">Выйти</b-dropdown-item>
      </b-nav-item-dropdown>
    </div>
  </div>
</template>

<script>
import { AUTH_REQUEST, AUTH_LOGOUT } from "@/store/actions/auth";

export default {
  name: "Login",
  data() {
    return {
      formUsername: "",
      password: ""
    };
  },
  computed: {
    isAuthenticated() {
      return this.$store.getters.isAuthenticated;
    },
    authStatus() {
      return this.$store.getters.authStatus;
    },
    currentUsername() {
      return this.$store.getters.username;
    }
  },
  methods: {
    login() {
      const username = this.formUsername;
      const password = this.password;
      this.$store
        .dispatch(AUTH_REQUEST, { username, password })
        .then(() => {
          this.$router.push("/");
        })
        .catch(() => {
          // Ошибка уже обработана в store
        });
    },
    logout() {
      this.$store.dispatch(AUTH_LOGOUT).then(() => {
        this.$router.push("/login");
      });
    }
  }
};
</script>

<style scoped>
/* Стили для формы входа */
.login-form {
  max-width: 400px;
  margin: 2rem auto;
  padding: 1rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-control {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.btn {
  padding: 0.5rem;
  margin-top: 1rem;
}

.alert {
  margin-top: 1rem;
  padding: 0.5rem;
  border-radius: 4px;
}

.alert-danger {
  background-color: #f8d7da;
  border-color: #f5c6cb;
  color: #721c24;
}

/* Стили для информации о пользователе в навбаре */
.nav-user-info {
  display: inline-flex;
  align-items: center;
  margin: 0;
  padding: 0;
}

.nav-user-info .username {
  font-size: 0.9rem;
  margin-right: 0.5rem;
}

/* Переопределение стилей Bootstrap для dropdown в навбаре */
:deep(.dropdown-toggle) {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
  line-height: 1.5;
}

:deep(.dropdown-menu) {
  font-size: 0.875rem;
  min-width: 120px;
}
</style>
