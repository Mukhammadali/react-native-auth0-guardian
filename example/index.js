/**
 * @format
 */

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

import Auth0Guardian from 'react-native-auth0-guardian';

const auth0Domain = 'YOUR_AUTH0_DOMAIN';
Auth0Guardian.initialize(auth0Domain);

AppRegistry.registerComponent(appName, () => App);
