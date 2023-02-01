import React, { useEffect } from 'react';
import { StyleSheet, View, Image, Button } from 'react-native';

export default function ScanResult({ navigation, route }) {
  const { params } = route || {};
  const { imageURI } = params || {};

  const searchSimilar = () =>
    navigation.navigate({
      name: 'SimilaritySearch',
      params: { imageURI },
    });

  useEffect(() => {
    if (!imageURI) {
      if (navigation.canGoBack()) {
        navigation.goBack();
      } else {
        navigation.navigate('Home');
      }
    }
  }, [imageURI]);

  return (
    <View style={styles.container}>
      {imageURI && (
        <>
          <Image
            resizeMode="contain"
            style={styles.image}
            source={{ uri: imageURI }}
          />
          <View style={styles.buttonContainer}>
            <Button
              title="Ver obras similares"
              color="rgba(0,0,0,0.75)"
              onPress={searchSimilar}
            />
          </View>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: '15%',
  },
  image: {
    width: '100%',
    height: '70%',
  },
  buttonContainer: {
    position: 'absolute',
    top: '85%',
    bottom: 0,
    alignSelf: 'center',
    justifyContent: 'center',
  },
});
