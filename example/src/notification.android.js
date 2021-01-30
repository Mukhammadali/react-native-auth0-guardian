import Auth0Guardian from 'react-native-auth0-guardian';
import firebase from 'react-native-firebase';
import AsyncStorage from '@react-native-community/async-storage';
import {constants} from 'src/constants';
import {AUTH0_GUARDIAN_DOMAIN} from 'src/config/auth0';
import {useEffect, useRef} from 'react';
import {useSelector, useDispatch} from 'react-redux';
import uuid from 'uuid';
import {updateChatNotifCountAction} from 'src/redux/chat/chatActions';
import showMFAPopup from './showPopup';
import syncStorage from './storage';
import AppMetada from '../app.json';

Auth0Guardian.initialize(AUTH0_GUARDIAN_DOMAIN).catch((err) =>
  console.log('Auth0Guardian', err),
);

// TODO: fix twilio-chat notification

const sendLocalNotification = ({
  notificationId,
  title = AppMetada.displayName,
  body,
  data,
  buttons = [],
}) => {
  try {
    const localNotification = new firebase.notifications.Notification({
      sound: 'default',
    })
      .setTitle(title)
      .setBody(body)
      .setData(data)
      .setNotificationId(notificationId || uuid.v1())
      // .setSound('default')
      .android.setChannelId('notification-action')
      .android.setSmallIcon('ic_launcher')
      .android.setPriority(firebase.notifications.Android.Priority.Max);
    // eslint-disable-next-line no-restricted-syntax
    for (const button of buttons) {
      localNotification.android.addAction(button);
      button.setShowUserInterface(false);
    }
    // trigger local notification
    firebase.notifications().displayNotification(localNotification);
  } catch (err) {
    console.log('err:', err);
  }
};

const handleOpenNotification = async (notification) => {
  await firebase
    .notifications()
    .removeDeliveredNotification(notification._notificationId);
  await showMFAPopup(notification._data);
};

export const getToken = () => firebase.messaging().getToken();
const initializeAsync = async () => {
  const token = await AsyncStorage.getItem(constants.FCM_TOKEN);
  if (!token) {
    const fcmToken = await firebase.messaging().getToken();
    syncStorage.set(constants.FCM_TOKEN, fcmToken);
  }
  const initialNotification = await firebase
    .notifications()
    .getInitialNotification();
  if (initialNotification?.notification?._data) {
    handleOpenNotification(initialNotification.notification);
  }
  const channel = new firebase.notifications.Android.Channel(
    'notification-action',
    'localnotification',
    firebase.notifications.Android.Importance.Max,
  ).setDescription('Local Channel');
  firebase.notifications().android.createChannel(channel);
  // remove all notifications on app open
  firebase.notifications().removeAllDeliveredNotifications();
};

export const showLocalNotification = () => {};

const checkNotificationEnabled = async () => {
  const enabled = await firebase.messaging().hasPermission();
  return enabled;
};

export default function initNotificationHook() {
  // eslint-disable-next-line react-hooks/rules-of-hooks
  useEffect(() => {
    initializeAsync();
    checkNotificationEnabled();
    firebase.notifications().onNotificationOpened((notificationOpen) => {
      if (
        notificationOpen?.notification?._data &&
        notificationOpen?.notification?._data?.sh?.includes(
          'guardian.auth0.com',
        )
      ) {
        handleOpenNotification(notificationOpen.notification);
      }
    });
    firebase.messaging().onTokenRefresh((fcmToken) => {
      syncStorage.set(constants.FCM_TOKEN, fcmToken);
    });
    firebase.messaging().onMessage(async (remoteMessage) => {
      if (
        remoteMessage?._data?.sh &&
        remoteMessage._data.sh.includes('guardian.auth0.com')
      ) {
        showMFAPopup(remoteMessage.data);
      }
    });
  }, []);
}

// Listen to background notification actions
export const handleAndroidBackgroundNotificationAction = async (
  notificationOpened,
) => {
  try {
    await Auth0Guardian.initialize(AUTH0_GUARDIAN_DOMAIN);
    firebase
      .notifications()
      .removeDeliveredNotification(
        notificationOpened.notification.notificationId,
      );
    if (notificationOpened.action === 'accept') {
      return Auth0Guardian.allow(notificationOpened.notification.data);
    }
    if (notificationOpened.action === 'reject') {
      return Auth0Guardian.reject(notificationOpened.notification.data);
    }
  } catch (err) {
    console.log(err);
  }
  return Promise.resolve();
};

// Listen to background notification and trigger displayLocalNotification
export const handleAndroidBackgroundNotification = async (remoteMessage) => {
  try {
    if (
      remoteMessage?.data?.sh &&
      remoteMessage.data.sh.includes('guardian.auth0.com')
    ) {
      const acceptAction = new firebase.notifications.Android.Action(
        'accept',
        'ic_launcher',
        'Accept',
      );
      const rejectAction = new firebase.notifications.Android.Action(
        'reject',
        'ic_launcher',
        'Reject',
      );
      sendLocalNotification({
        notificationId: 'default',
        body: 'Do you confirm?',
        data: remoteMessage.data,
        buttons: [acceptAction, rejectAction],
      });
    } else if (remoteMessage?.messageId) {
      sendLocalNotification({
        body: remoteMessage?.data?.twi_body,
        notificationId: remoteMessage.messageId,
      });
    }
  } catch (err) {
    console.log('err:', err);
  }
  return Promise.resolve();
};
