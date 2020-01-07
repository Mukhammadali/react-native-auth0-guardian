
# react-native-auth0-guardian

## Getting started

`$ npm install react-native-auth0-guardian --save`

### Mostly automatic installation

`$ react-native link react-native-auth0-guardian`

### Manual installation


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
      compile project(':react-native-auth0-guardian')
  	```

## Usage
```javascript
import RNAuth0Guardian from 'react-native-auth0-guardian';

// TODO: What to do with the module?
RNAuth0Guardian;
```
  