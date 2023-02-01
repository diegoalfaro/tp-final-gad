import axios from "axios";
import axiosRetry from "axios-retry";
import FormData from "form-data";
import { apiBaseUrl } from "./config.js";

const axiosInstance = axios.create({
  baseURL: apiBaseUrl,
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

export const waitInitiation = async () => {
  const checkStatus = async () => {
    try {
      const { data } = await axiosInstance.get("/");
      return !!data?.status;
    } catch {
      return false;
    }
  };

  function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  let status = false;

  do {
    status = await checkStatus();
    await delay(2000);
  } while (!status);

  return status;
};

export const getAllArtworks = async () => {
  const { data } = await axiosInstance.get("/artworks");
  return data;
};

export const getSimilarArtworks = async (imgData) => {
  const data = new FormData();
  data.append("image", imgData);
  const response = await axiosInstance.post("/artworks/similar", data, {
    header: data.getHeaders(),
    params: {
      limit: 5,
    },
  });
  return response?.data;
};
