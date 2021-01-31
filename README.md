
# React Native Auth0 Guardian (iOS & Android)

[![npm version](https://badge.fury.io/js/react-native-auth0-guardian.svg)](https://www.npmjs.com/package/react-native-auth0-guardian)
[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://www.npmjs.com/package/react-native-auth0-guardian)

## Installation

### NPM

`npm install --save react-native-auth0-guardian`

### Yarn

`yarn add react-native-auth0-guardian`



### Linking the library

**React Native 0.60+**:  CLI autolink feature links the module while building the app. No any extra steps needed.

**React Native <= 0.59**: You need to link manually   
`$ react-native link react-native-auth0-guardian`


Use CocoaPods to add the native RNAuth0Guardian to your project:   
`$ npx pod-install`

### Manual installation
<details>
<summary>Show Steps</summary>
<br>




#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-auth0-guardian` and add `RNAuth0Guardian.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNAuth0Guardian.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNAuth0GuardianPackage;` to the imports at the top of the file
  - Add `new RNAuth0GuardianPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-auth0-guardian'
  	project(':react-native-auth0-guardian').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-auth0-guardian/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      implementation project(':react-native-auth0-guardian')
  	```
</details>

## Usage
### Initialization
```javascript
import Auth0Guardian from 'react-native-auth0-guardian';

// Before using `Auth0Guardian`, you should call `initialize` method 
// with `auth0Domain` as a parameter. Calling this in the root file is recommended Ex: root index.js or App.js

const auth0Domain = "yourtenant.guardian.auth0.com" // replace it with your own

Auth0Guardian.initialize(auth0Domain)
	.then(result => console.log('Auth0 Guardian initialized 😎'))
	.catch(err => console.log(err))
```

### Enrolling the device

An enrollment is a link between the second factor and an Auth0 account. When an account is enrolled you'll need it to provide the second factor required to verify the identity.

For an enrollment you need the following things, besides your Guardian Domain:

`enrollmentUri` - this is the url parsed from qr code. You can use *react-native-qrcode-scanner* library to scan the qrcode and parse it.   

`deviceToken` - unique device token (aka FCM token for android, APNS token for iOS). You can get it using react-native push notification libraries

```javascript
try {
	const isEnrolled = await Auth0Guardian.enroll(enrollmentUri, deviceToken);
	console.log({ isEnrolled })
} catch (err)  {
	console.log(err)
}
```

### Get TOTP code for current enrollment. (Returns only if the device is enrolled successfully) 
You can also get TOTP code and show it inside your application if this use case is required. User will have 2 options: notification based authentication or totp based authentication (like *Google Authenticator*)

```javascript
try {
	const totpCode = await Auth0Guardian.getTOTP();
	console.log({ totpCode })
} catch (err) {
	console.log(err)
}
```

### Allow a login request.
Once you have the enrollment in place, you will receive a push notification every time the user has to validate his identity with MFA.

`notificationData` - body of notification received through push notification libraries (firebase, push-notification-ios or etc.)

```javascript
try {
	const isAllowed = await Auth0Guardian.allow(notificationData);
	console.log({ isAllowed })
} catch (err) {
	console.log(err)
}
```

### Reject a login request.
To deny an authentication request use the method below.

`notificationData` - body of notification received through push notification libraries (firebase, push-notification-ios or etc.)

```javascript
try {
	const isRejected = await Auth0Guardian.reject(notificationData);
	console.log({ isRejected })
} catch (err) {
	console.log(err)
}
```

### Removing  device enrollment
If you want to delete an enrollment -for example if you want to disable MFA

```javascript
try {
	const isUnenrolled = await Auth0Guardian.unenroll();
	console.log({ isUnenrolled })
} catch (err) {
	console.log(err)
}
```


## Native libraries used:

[Auth0 Guardian Java](https://github.com/auth0/Guardian.java)   
[Auth0 Guardian Swift](https://github.com/auth0/Guardian.swift)


