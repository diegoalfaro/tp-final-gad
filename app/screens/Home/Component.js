import React, { useEffect, useState } from 'react';
import { StyleSheet, FlatList, RefreshControl } from 'react-native';

import { Artwork } from '../../components';

import { getRandomArtworks } from '../../services/ApiService';

export default function Home() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);

  const loadData = () => {
    setLoading(true);
    getRandomArtworks()
      .then(({ data }) => setItems(data))
      .catch(error => console.error(error))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadData();
  }, []);

  return (
    <FlatList
      contentContainerStyle={styles.container}
      data={items}
      keyExtractor={item => item.id}
      renderItem={({ item }) => <Artwork item={item} />}
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
    backgroundColor: 'black',
  },
});
