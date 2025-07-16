import yaml from 'js-yaml';
import usersConfig from '@/config/users.yaml';

class AuthService {
  constructor() {
    this.users = usersConfig.users;
    this.systemConfig = usersConfig.system;
  }

  validateUser(username, password) {
    const user = this.users.find(u => u.username === username && u.password === password);
    return !!user;
  }

  getCamundaAuth() {
    return {
      username: this.systemConfig.camunda.username,
      password: this.systemConfig.camunda.password,
      base64: this.systemConfig.camunda.base64
    };
  }
}

export default new AuthService(); 