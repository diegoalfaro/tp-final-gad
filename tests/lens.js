import axios from "axios";
import axiosRetry from "axios-retry";

const axiosInstance = axios.create({
  baseURL: 'https://lens.google.com'
});

axiosRetry(axiosInstance, {
  retries: 5,
  retryDelay: (retryCount) => {
    console.log(`Retry attempt: ${retryCount}`);
    return retryCount * 2000;
  },
  retryCondition: (error) => {
    return error?.response?.status != 200;
  },
});

export const getUploadId = async () => {
  const config = {
    method: "post",
    url: "/_/upload/?hl=es-AR",
    headers: {
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "x-client-side-image-upload": "true",
      "x-goog-upload-command": "start",
      "x-goog-upload-protocol": "resumable",
    },
  };

  const { headers } = await axiosInstance(config);
  const uploadId = headers["x-guploader-uploadid"];

  return uploadId;
};

export const uploadImage = async (uploadId, data) => {
  const config = {
    method: "post",
    url: `/_/upload/?hl=es-AR&upload_id=${uploadId}&upload_protocol=resumable`,
    headers: {
      "content-type": "application/x-www-form-urlencoded;charset=utf-8",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "x-client-side-image-upload": "true",
      "x-goog-upload-command": "upload, finalize",
      "x-goog-upload-offset": "0",
    },
    data: data,
  };

  const response = await axiosInstance(config);

  return JSON.parse(response.data.slice(4));
};

export const getSearchResult = async (url) => {
  const config = { method: "get", url };
  const { data } = await axiosInstance(config);

  const regex = /"Buscar (?<name>[^"]+) con imágenes"/gmu;
  const result = regex.exec(data)?.groups?.name;

  return result;
};

export const getNameFromImage = async (data) => {
  const uploadId = await getUploadId();
  const { url } = await uploadImage(uploadId, data);
  const searchResult = await getSearchResult(url);
  return searchResult;
};
