/* eslint-disable no-underscore-dangle */
import {useEffect} from 'react';
import NotificationActions from 'react-native-ios-notification-actions';
import Auth0Guardian from 'react-native-auth0-guardian';
import PushNotificationIOS from '@react-native-community/push-notification-ios';
import showMFAPopup from './showPopup';
import {AsyncStorage} from 'react-native';

const upvoteButton = new NotificationActions.Action(
  {
    activationMode: 'background',
    title: 'Allow',
    identifier: 'ALLOW_ACTION',
  },
  (res, done) => {
    const {aps, mfa} = res.userInfo;
    Auth0Guardian.allow({
      mfa,
      aps: {
        alert: aps.alert,
        category: aps.category,
      },
    })
      .then(() => done())
      .catch((err) => console.log(err));
  },
);

const rejectButton = new NotificationActions.Action(
  {
    activationMode: 'background',
    title: 'Reject',
    identifier: 'REJECT_ACTION',
  },
  (res, done) => {
    const {aps, mfa} = res.userInfo;
    Auth0Guardian.reject({
      mfa,
      aps: {
        alert: aps.alert,
        category: aps.category,
      },
    })
      .then(() => done())
      .catch((err) => console.log(err));
  },
);

// action buttons category
const myCategory = new NotificationActions.Category({
  identifier: 'com.auth0.notification.authentication',
  actions: [upvoteButton, rejectButton],
  forContext: 'default',
});

export const getToken = (callback) => {
  PushNotificationIOS.addEventListener('register', callback);
};

export const showLocalNotification = () => {};

export default function useNotificationListener() {
  const onClickNotification = (notification) => {
    if (notification._data.mfa) {
      // auth0 MFA notification
      const data = {
        mfa: notification._data.mfa,
        aps: {
          alert: notification._alert,
          category: notification._category,
        },
      };
      showMFAPopup(data);
    }
  };
  const onRegister = (deviceToken) => {
    try {
      if (deviceToken) {
        AsyncStorage.setItem('DEVICE_TOKEN', deviceToken);
      }
    } catch (e) {
      console.log('ERROR in storing devicetoken', e);
    }
  };

  useEffect(() => {
    PushNotificationIOS.addEventListener('notification', (notificaiton) =>
      onClickNotification(notificaiton),
    );
    PushNotificationIOS.addEventListener('register', onRegister);
    NotificationActions.updateCategories([myCategory]);
    PushNotificationIOS.checkPermissions((res) => {
      if (!Object.keys(res).every((key) => !!res[key])) {
        PushNotificationIOS.requestPermissions();
      }
    });
    return () => {
      PushNotificationIOS.removeEventListener(
        'notification',
        onClickNotification,
      );
      PushNotificationIOS.removeEventListener('register', onRegister);
    };
  }, []);
}
