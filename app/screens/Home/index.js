import { StyleSheet } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import Icon from 'react-native-vector-icons/FontAwesome';
import { useScanner } from '../../hooks/ScannerHook';

import Component from './Component';

const name = 'Home';

function HeaderRight({ tintColor }) {
  const { scanPicture } = useScanner();
  const navigation = useNavigation();

  const takePicture = async () => {
    const imageURI = await scanPicture();
    if (imageURI) {
      navigation.navigate('ScanResult', { imageURI });
    }
  };

  return (
    <Icon.Button
      name="camera"
      color={tintColor}
      onPress={takePicture}
      backgroundColor="transparent"
      iconStyle={styles.headerButtonIcon}
      style={styles.headerButton}
      solid
    />
  );
}

const styles = StyleSheet.create({
  headerButton: {
    justifyContent: 'center',
    alignItems: 'center',
    padding: 0,
  },
  headerButtonIcon: {
    marginTop: 0,
    marginBottom: 0,
    marginLeft: 0,
    marginRight: 0,
  },
});

const options = {
  title: 'Inicio',
  headerTransparent: true,
  headerStyle: {
    backgroundColor: 'rgba(0,0,0,0.75)',
  },
  headerTintColor: 'white',
  headerShadowVisible: false,
  headerRight: props => <HeaderRight {...props} />,
  statusBarTranslucent: true,
  statusBarColor: 'transparent',
};

export default {
  name,
  options,
  Component,
};
