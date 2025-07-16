import axios from 'axios';
import AuthService from '@/services/auth.service';

const createApiInstance = () => {
  const camundaAuth = AuthService.getCamundaAuth();
  
  const instance = axios.create({
    headers: {
      'Authorization': `Basic ${camundaAuth.base64}`,
      'Content-Type': 'application/json'
    }
  });

  return instance;
};

export default createApiInstance;

export function getEntity(path, entity, query) {
  const axiosInstance = createApiInstance();
  let finalPath = path;
  if (entity) {
    finalPath += "/" + entity;
  }
  if (query) {
    finalPath += "?" + query;
  }
  return axiosInstance.get(finalPath).then(response => response.data);
}
