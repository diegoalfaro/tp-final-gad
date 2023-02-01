import React from 'react';
import { DefaultTheme, NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { Home, Camera, SimilaritySearch, AddArtwork } from './screens';

const AppTheme = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...DefaultTheme.colors,
    background: 'black',
  },
};

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer theme={AppTheme}>
      <Stack.Navigator
        screenOptions={{
          animation: 'slide_from_right',
          presentation: 'card',
        }}>
        <Stack.Screen
          name={Home.name}
          component={Home.Component}
          options={Home.options}
        />
        <Stack.Screen
          name={Camera.name}
          component={Camera.Component}
          options={Camera.options}
        />
        <Stack.Screen
          name={SimilaritySearch.name}
          component={SimilaritySearch.Component}
          options={SimilaritySearch.options}
        />
        <Stack.Screen
          name={AddArtwork.name}
          component={AddArtwork.Component}
          options={AddArtwork.options}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
