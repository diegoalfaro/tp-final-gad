import React from 'react';
import {
  StyleSheet,
  Image,
  Text,
  View,
  ImageBackground,
  Button,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';

export default function Artwork({ item }) {
  const {
    id,
    title,
    image_url,
    artist_name,
    artist_birth_year,
    artist_death_year,
    distance,
    percentage_similarity,
  } = item;

  const navigation = useNavigation();

  const searchSimilar = () =>
    navigation.navigate('SimilaritySearch', { artworkId: id });

  return (
    <View style={styles.container}>
      <ImageBackground
        style={styles.imageBackground}
        source={{ uri: image_url }}
        blurRadius={20}>
        <Image
          resizeMode="contain"
          source={{ uri: image_url }}
          style={styles.image}
        />
        <View style={styles.content}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.artist}>
            {artist_name} ({artist_birth_year} - {artist_death_year})
          </Text>
          <View style={styles.badgesContainer}>
            {percentage_similarity >= 0 ? (
              <View style={styles.badge}>
                <Text>Similitud: {percentage_similarity}%</Text>
              </View>
            ) : (
              React.Fragment
            )}
            {distance >= 0 ? (
              <View style={styles.badge}>
                <Text>Distancia: {parseFloat(distance).toFixed(2)}</Text>
              </View>
            ) : (
              React.Fragment
            )}
          </View>
          {!percentage_similarity || percentage_similarity < 100 ? (
            <View style={styles.buttonContainer}>
              <Button
                title="Ver similares"
                color="rgba(0,0,0,0.75)"
                onPress={searchSimilar}
              />
            </View>
          ) : (
            React.Fragment
          )}
        </View>
      </ImageBackground>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#333',
    justifyContent: 'center',
    marginVertical: 8,
    marginHorizontal: 16,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 8,
    borderRadius: 8,
    overflow: 'hidden',
  },
  imageBackground: {
    flex: 1,
  },
  content: {
    padding: 20,
  },
  image: {
    height: 200,
    width: '100%',
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    color: 'white',
    textShadowColor: '#000',
    textShadowOffset: {
      width: 0,
      height: 0,
    },
    textShadowOpacity: 0.75,
    textShadowRadius: 8,
  },
  artist: {
    fontSize: 16,
    color: 'white',
    textShadowColor: '#000',
    textShadowOffset: {
      width: 0,
      height: 0,
    },
    textShadowOpacity: 0.75,
    textShadowRadius: 10,
  },
  badgesContainer: {
    flex: 1,
    flexDirection: 'row',
    marginTop: 8,
  },
  badge: {
    backgroundColor: 'rgba(255,255,255,0.9)',
    marginRight: 8,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 50,
  },
  buttonContainer: {
    marginTop: 16,
  },
});
