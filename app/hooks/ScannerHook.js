import { Alert, PermissionsAndroid } from 'react-native';
import Scanner, { ResponseType } from 'react-native-document-scanner-plugin';

export function useScanner({ responseType = ResponseType.ImageFilePath } = {}) {
  const requestPermissions = async () => {
    const result = await PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.CAMERA,
      {
        title: 'Se necesitan permisos para la cámara',
        message:
          'Para usar esta funcionalidad se necesitan permisos para la cámara.',
        buttonNeutral: 'Preguntarme después',
        buttonNegative: 'Cancelar',
        buttonPositive: 'Dar permisos',
      },
    );

    return result === PermissionsAndroid.RESULTS.GRANTED;
  };

  const scanPictures = async ({ maxNumDocuments }) => {
    const granted = await requestPermissions();

    if (!granted) {
      Alert.alert(
        'Se necesitan permisos para la cámara',
        'Para usar esta funcionalidad se necesitan permisos para la cámara.',
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
      return;
    }

    const { scannedImages } = await Scanner.scanDocument({
      maxNumDocuments,
      responseType,
    });
    return scannedImages;
  };

  const scanPicture = async () => {
    const [image] = (await scanPictures({ maxNumDocuments: 1 })) || [];
    return image;
  };

  return { scanPicture };
}
