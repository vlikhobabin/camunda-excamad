import axios from "axios";
import store from "../store/store";

const createApiInstance = () => {
  const headers = {
    "Content-Type": "application/json",
    Accept: "application/json"
  };

  if (store.state.restToken) {
    headers.Authorization = "Bearer " + store.state.restToken;
  }

  return axios.create({
    baseURL: store.state.baseurl,
    headers: headers
  });
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
