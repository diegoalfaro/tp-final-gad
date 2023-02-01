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

export default function Artwork({ imageURI }) {
  const navigation = useNavigation();

  const addArtwork = () => navigation.navigate('AddArtwork', { imageURI });
  return (
    <View style={styles.container}>
      <ImageBackground
        style={styles.imageBackground}
        source={{ uri: imageURI }}
        blurRadius={20}>
        <Image
          resizeMode="contain"
          source={{ uri: imageURI }}
          style={styles.image}
        />
        <View style={styles.content}>
          <Text style={styles.title}>¿Obra de arte no disponible?</Text>
          <Text style={styles.subtitle}>
            Podés agregarla a la base de datos
          </Text>
          <View style={styles.buttonContainer}>
            <Button
              title="Agregar obra de arte"
              color="rgba(0,0,0,0.75)"
              onPress={addArtwork}
            />
          </View>
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
  subtitle: {
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
    marginTop: 8,
  },
});
