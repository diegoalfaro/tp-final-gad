import axios from 'axios';
import axiosRetry from 'axios-retry';
import { apiBaseURL as baseURL } from '../config/config';

const axiosInstance = axios.create({ baseURL });

axiosRetry(axiosInstance, {
  retries: 5,
  retryDelay: retryCount => {
    console.log(`Retry attempt: ${retryCount}`);
    return retryCount * 2000;
  },
  retryCondition: error => {
    return error?.response?.status != 200;
  },
});

export const getAllArtworks = () => axiosInstance.get('/artworks');

export const getRandomArtworks = () => axiosInstance.get('/artworks/random');

export const getSimilarArtworksByArtworkId = artworkId =>
  axiosInstance.get(`/artworks/similar/${artworkId}`);

export const getSimilarArtworksByImageURI = async uri => {
  const data = new FormData();
  data.append('image', { uri, name: 'artwork_image.jpg', type: 'image/jpeg' });
  const response = await axiosInstance.post('/artworks/similar', data, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response;
};

export const addArtwork = async ({ title, artistId, uri }) => {
  const data = new FormData();
  data.append('title', title);
  data.append('artist_id', artistId);
  data.append('image', { uri, name: 'artwork_image.jpg', type: 'image/jpeg' });
  const response = await axiosInstance.post('/artworks', data, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response;
};

export const getArtists = () => axiosInstance.get('/artists');
