import React, { useEffect, useMemo, useState } from 'react';
import { StyleSheet, RefreshControl, FlatList } from 'react-native';
import { matchPercentage } from '../../config/config';

import { Artwork, AddArtwork } from '../../components';

import {
  getSimilarArtworksByArtworkId,
  getSimilarArtworksByImageURI,
} from '../../services/ApiService';

export default function SimilaritySearch({ route }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const { params } = route || {};
  const { imageURI, artworkId } = params || {};

  const notShouldExists = useMemo(
    () => items?.every(item => item.percentage_similarity < matchPercentage),
    [items],
  );

  const loadDataByMethod = (method, param) => {
    setLoading(true);
    method(param)
      .then(({ data }) => setItems(data))
      .catch(error => console.error(error))
      .finally(() => setLoading(false));
  };

  const loadData = () => {
    if (artworkId) {
      loadDataByMethod(getSimilarArtworksByArtworkId, artworkId);
    } else if (imageURI) {
      loadDataByMethod(getSimilarArtworksByImageURI, imageURI);
    }
  };

  useEffect(() => {
    setItems([]);
    loadData();
  }, [artworkId, imageURI]);

  return (
    <FlatList
      contentContainerStyle={styles.container}
      data={items}
      keyExtractor={item => item.id}
      renderItem={({ item }) => <Artwork item={item} />}
      ListFooterComponent={
        imageURI && notShouldExists && items?.length > 0 ? (
          <AddArtwork imageURI={imageURI} />
        ) : undefined
      }
      refreshControl={
        <RefreshControl
          onRefresh={loadData}
          refreshing={loading}
          colors={['white']}
          progressBackgroundColor="black"
          size="large"
          progressViewOffset={120}
        />
      }
    />
  );
}

const styles = StyleSheet.create({
  container: {
    paddingTop: 101,
    paddingBottom: 8,
  },
});
