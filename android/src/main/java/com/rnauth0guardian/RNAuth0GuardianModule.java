
package com.rnauth0guardian;

import android.content.SharedPreferences;
import android.util.Log;

import com.auth0.android.guardian.sdk.CurrentDevice;
import com.auth0.android.guardian.sdk.Enrollment;
import com.auth0.android.guardian.sdk.Notification;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.auth0.android.guardian.sdk.Guardian;
import com.google.gson.Gson;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import android.content.SharedPreferences.Editor;

import static android.content.Context.MODE_PRIVATE;


public class RNAuth0GuardianModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
//  public String domain = "<TENANT>.guardian.auth0.com";
  public Guardian guardian = null;
  SharedPreferences  mPrefs;
  private static final String ENROLLMENT = "ENROLLMENT";

  public RNAuth0GuardianModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    mPrefs = this.reactContext.getSharedPreferences("myPrefsKeys", MODE_PRIVATE);
  }

  private Enrollment getEnrollment(){
    Gson gson = new Gson();
    String json = mPrefs.getString(ENROLLMENT, null);
    Enrollment obj = gson.fromJson(json, Enrollment.class);
    return obj ;
  }

  private void saveEnrollment(Enrollment enrollment){
    Editor prefsEditor = mPrefs.edit();
    Gson gson = new Gson();
    String json = gson.toJson(enrollment);
    prefsEditor.putString(ENROLLMENT, json);
    prefsEditor.commit();
  }

  @Override
  public String getName() {
    return "RNAuth0Guardian";
  }


  @ReactMethod
  public void enroll(String enrollmentURI, String FCMToken, String domain, Promise promise){
    String deviceName = android.os.Build.MODEL;
    CurrentDevice device = new CurrentDevice(this.reactContext, FCMToken, deviceName);
    try {
      KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("NONEwithRSA");
      keyPairGenerator.initialize(2048); // you should use at least 2048 bit keys
      KeyPair keyPair = keyPairGenerator.generateKeyPair();
      Guardian guardian = new Guardian.Builder()
              .domain(domain)
              .build();
      Enrollment enrollment = guardian
              .enroll(enrollmentURI, device, keyPair)
              .execute();
      Log.e("ENROLLMENT", enrollment.toString());
      saveEnrollment(enrollment);
      promise.resolve(enrollment);
//      System.out.println("Enrollment", enrollment);
    } catch (Exception err){
      promise.reject(err);
      Log.e("AUTH0 GUARDIAN", "ENROLLMENT EXCEPTION", err);
    }

  }

  @ReactMethod
  public void allow(Notification notification) {
    try {
      Enrollment enrollment = getEnrollment();
      if(enrollment != null) {
        guardian
                .allow(notification, enrollment)
                .execute();
      }
    } catch (Exception err){
      Log.e("AUTH0", "ALLOW FAILD", err);
    }
  }

  @ReactMethod
  public void reject(Notification notification) {
    try {
      Enrollment enrollment = getEnrollment();
      if(enrollment != null) {
        guardian
                .allow(notification, enrollment)
                .execute();
      }
    } catch (Exception err){
      Log.e("AUTH0", "ALLOW FAILD", err);
    }
  }

  @ReactMethod
  public void unenroll(){
    try {
      Enrollment enrollment = getEnrollment();
      if(enrollment != null){
        guardian
                .delete(enrollment)
                .execute();
      }
    } catch (Exception err) {
      Log.e("AUTH0", "UNENROLLMENT FAILED", err);
    }

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