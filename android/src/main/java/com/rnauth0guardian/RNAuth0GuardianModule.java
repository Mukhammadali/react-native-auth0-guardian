
package com.rnauth0guardian;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
//import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;

public class RNAuth0GuardianModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNAuth0GuardianModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNAuth0GuardianAndroid";
  }

  @ReactMethod
  public void test(Promise promise) {
    try {
      promise.resolve("WORKING!");
    } catch (Exception e) {
      promise.reject("ERROR", "ERROR WORKING");
    }
  }
}