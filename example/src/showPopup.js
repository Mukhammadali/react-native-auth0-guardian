import {Alert} from 'react-native';
import Auth0Guardian from '../..';

const showMFAPopup = (notificationData) => {
  Alert.alert({
    title: 'Do you confirm?',
    description: 'Your other device is trying to login',
    cancelText: 'Reject',
    okText: 'Allow',
    onOk: () => {
      Auth0Guardian.allow(notificationData).catch(console.log);
    },
    onCancel: () => {
      Auth0Guardian.reject(notificationData).catch(console.log);
    },
  });
};

export default showMFAPopup;
