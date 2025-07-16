/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { AUTH_REQUEST, AUTH_ERROR, AUTH_SUCCESS, AUTH_LOGOUT } from '../actions/auth';
import AuthService from '@/services/auth.service';

const state = {
  token: localStorage.getItem('user-token') || '',
  status: '',
  username: localStorage.getItem('username') || ''
};

const getters = {
  isAuthenticated: state => !!state.token,
  authStatus: state => state.status,
  username: state => state.username
};

const actions = {
  [AUTH_REQUEST]: ({ commit }, { username, password }) => {
    return new Promise((resolve, reject) => {
      commit(AUTH_REQUEST);
      if (AuthService.validateUser(username, password)) {
        const token = btoa(`${username}:${password}`);
        localStorage.setItem('user-token', token);
        localStorage.setItem('username', username);
        commit(AUTH_SUCCESS, { token, username });
        resolve();
      } else {
        commit(AUTH_ERROR);
        localStorage.removeItem('user-token');
        localStorage.removeItem('username');
        reject(new Error('Invalid credentials'));
      }
    });
  },

  [AUTH_LOGOUT]: ({ commit }) => {
    return new Promise(resolve => {
      commit(AUTH_LOGOUT);
      localStorage.removeItem('user-token');
      localStorage.removeItem('username');
      resolve();
    });
  }
};

const mutations = {
  [AUTH_REQUEST]: (state) => {
    state.status = 'loading';
  },
  [AUTH_SUCCESS]: (state, { token, username }) => {
    state.status = 'success';
    state.token = token;
    state.username = username;
  },
  [AUTH_ERROR]: (state) => {
    state.status = 'error';
  },
  [AUTH_LOGOUT]: (state) => {
    state.token = '';
    state.username = '';
    state.status = '';
  }
};

export default {
  state,
  getters,
  actions,
  mutations
};
