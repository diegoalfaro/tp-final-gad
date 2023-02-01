import React, { useEffect } from 'react';
import {
  StyleSheet,
  View,
  Button,
  ScrollView,
  TextInput,
  Image,
  ImageBackground,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { CommonActions } from '@react-navigation/native';
import SelectDropdown from 'react-native-select-dropdown';
import Icon from 'react-native-vector-icons/FontAwesome';
import { addArtwork, getArtists } from '../../services/ApiService';

export default function ScanResult({ navigation, route }) {
  const { params } = route || {};
  const { imageURI } = params || {};

  const [title, onChangeTitle] = React.useState('');
  const [artist, setArtist] = React.useState(undefined);
  const [artists, setArtists] = React.useState([]);
  const [loading, setLoading] = React.useState(false);

  const onSuccess = artwork =>
    Alert.alert(
      '¡Gracias por tu aporte!',
      'La obra de arte se agregó correctamente.',
      [
        {
          text: 'Ver similares',
          onPress: () =>
            navigation.dispatch(
              CommonActions.reset({
                index: 1,
                routes: [
                  { name: 'Home' },
                  {
                    name: 'SimilaritySearch',
                    params: { artworkId: artwork.id },
                  },
                ],
              }),
            ),
          style: 'cancel',
        },
      ],
      {
        cancelable: true,
      },
    );

  const onError = () =>
    Alert.alert(
      'Disculpe las molestias',
      'No fue posible agregar la obra de arte, pruebe nuevamente en otro momento.',
      [
        {
          text: 'Entendido',
          style: 'cancel',
        },
      ],
      {
        cancelable: true,
      },
    );

  const submitForm = () => {
    setLoading(true);
    addArtwork({ title, artistId: artist.id, uri: imageURI })
      .then(({ data }) => onSuccess(data))
      .catch(onError)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    getArtists()
      .then(({ data }) => setArtists(data))
      .catch(error => console.error(error));
  }, []);

  useEffect(() => {
    if (!imageURI) {
      if (navigation.canGoBack()) {
        navigation.goBack();
      } else {
        navigation.navigate('Home');
      }
    }
  }, [imageURI]);

  const validForm = title && title !== '' && artist;

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {loading || !imageURI ? (
        <ActivityIndicator
          style={styles.activityIndicator}
          color="white"
          size="large"
        />
      ) : (
        <View style={styles.form}>
          <View>
            <ImageBackground
              style={styles.imageBackground}
              source={{ uri: imageURI }}
              blurRadius={20}>
              <Image
                resizeMode="contain"
                style={styles.image}
                source={{ uri: imageURI }}
              />
            </ImageBackground>
          </View>
          <TextInput
            onChangeText={onChangeTitle}
            value={title}
            style={styles.titleInput}
            placeholder="Título de la obra"
            placeholderTextColor="rgba(255,255,255,0.6)"
            cursorColor="white"
            textAlign="left"
            underlineColorAndroid="white"
          />
          <SelectDropdown
            search
            statusBarTranslucent
            data={artists}
            defaultValue={artist}
            onSelect={selectedItem => setArtist(selectedItem)}
            buttonTextAfterSelection={({ name }) => `Artista: ${name}`}
            rowTextForSelection={({ name }) => name}
            defaultButtonText="Seleccionar artista..."
            buttonStyle={styles.artistInput.button}
            buttonTextStyle={styles.artistInput.button.text}
            dropdownStyle={styles.artistInput.dropdown}
            renderDropdownIcon={() => (
              <Icon name="chevron-down" color="white" />
            )}
            renderSearchInputRightIcon={() => <Icon name="search" />}
          />
          <View style={styles.buttonContainer}>
            {validForm ? (
              <Button
                title="Agregar obra de arte"
                color="rgba(0,0,0,0.75)"
                disabled={!validForm}
                onPress={submitForm}
              />
            ) : (
              React.Fragment
            )}
          </View>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    minHeight: '100%',
    padding: 8,
    paddingTop: 100,
  },
  form: {
    flex: 1,
    flexDirection: 'column',
  },
  imageBackground: {
    flex: 1,
  },
  image: {
    width: '100%',
    height: 320,
  },
  titleInput: {
    fontSize: 16,
    color: 'white',
    backgroundColor: 'black',
    borderBottomWidth: 1,
    width: '100%',
    marginTop: 32,
  },
  artistInput: {
    button: {
      marginTop: 32,
      width: '100%',
      backgroundColor: 'black',
      text: {
        fontSize: 16,
        color: 'white',
        textAlign: 'left',
        marginLeft: 0,
      },
    },
  },
  buttonContainer: {
    flex: 1,
    marginTop: 32,
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'center',
    flexGrow: 1,
  },
  activityIndicator: {
    marginTop: 30,
  },
});
