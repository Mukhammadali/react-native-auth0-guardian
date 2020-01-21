//
//  RNAuth0GuardianModule.java
//  RNAuth0Guardian
//
//  Created by Mukhammad Ali on 2020/01/07.
//  Copyright © 2020. All rights reserved.
//

package com.rnauth0guardian;

import android.content.SharedPreferences;
import android.util.Log;

import com.auth0.android.guardian.sdk.CurrentDevice;
import com.auth0.android.guardian.sdk.Enrollment;
import com.auth0.android.guardian.sdk.Notification;
import com.auth0.android.guardian.sdk.ParcelableNotification;
import com.auth0.android.guardian.sdk.networking.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.auth0.android.guardian.sdk.Guardian;
import com.facebook.react.bridge.ReadableMap;

import java.security.KeyPair;
import java.security.KeyPairGenerator;

import java.security.NoSuchAlgorithmException;
import java.util.Map;

import static android.content.Context.MODE_PRIVATE;


public class RNAuth0GuardianModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private static final String TAG = RNAuth0GuardianModule.class.getName();

  private Guardian guardian;
  SharedPreferences mPrefs;
  private ParcelableEnrollment enrollment;

  private static final String ENROLLMENT = "ENROLLMENT";
  private static final Exception DEVICE_NOT_ENROLLED_EXCEPTION = new IllegalStateException("DEVICE_NOT_ENROLLED");

  public RNAuth0GuardianModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    mPrefs = this.reactContext.getSharedPreferences("myPrefsKeys", MODE_PRIVATE);
  }

  private ParcelableEnrollment getEnrollment(){
    String json = mPrefs.getString(ENROLLMENT, "");
    Log.e(TAG, json);
    return ParcelableEnrollment.fromJSON(json);
  }

  private void saveEnrollment(Enrollment data){
    SharedPreferences.Editor prefsEditor = mPrefs.edit();
    ParcelableEnrollment parcelableEnrollment = new ParcelableEnrollment(data);
    enrollment = parcelableEnrollment;
    String json = parcelableEnrollment.toJSON();
    prefsEditor.putString(ENROLLMENT, json);
    prefsEditor.commit();
  }

  @ReactMethod
  public void initialize(String domain, Promise promise) {
    try {
      guardian = new Guardian.Builder()
        .domain(domain)
        .build();
      enrollment = getEnrollment();
      promise.resolve(true);
      Log.i("SAVED ENROLLMENT", enrollment.toJSON());
    } catch (Exception err){
      promise.reject(err);
    }
  }

  private KeyPair generateKeyPair() {
    try {
      KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
      keyPairGenerator.initialize(2048); // at least 2048 bits!
      return keyPairGenerator.generateKeyPair();
    } catch (NoSuchAlgorithmException e) {
      Log.e(TAG, "Error generating keys", e);
    }

    return null;
  }

  @Override
  public String getName() {
    return "RNAuth0Guardian";
  }

  @ReactMethod
  public void enroll(String enrollmentURI, String FCMToken, final Promise promise){
    String deviceName = android.os.Build.MODEL;
    CurrentDevice device = new CurrentDevice(this.reactContext, FCMToken, deviceName);
    try {
      KeyPair keyPair = generateKeyPair();
      if(keyPair != null) {
        guardian
          .enroll(enrollmentURI, device, keyPair)
          .start(new Callback<Enrollment>() {
            @Override
            public void onSuccess(Enrollment response) {
              Log.i(TAG, "ENROLLED SUCCESSFULLY!");
              promise.resolve(response.getSecret());
              saveEnrollment(response);
            }

            @Override
            public void onFailure(Throwable exception) {
              Log.i(TAG, "ENROLL FAILED!");
              promise.reject(exception);
            }
          });
      }

    } catch (Exception err){
      promise.reject(err);
      Log.e("AUTH0 GUARDIAN", "ENROLLMENT EXCEPTION", err);
    }

  }

  @ReactMethod
  public void getTOTP(Promise promise){
    try {
      if(enrollment != null){
        String totpCode = Guardian.getOTPCode(enrollment);
        promise.resolve(totpCode);
      } else {
        promise.reject(DEVICE_NOT_ENROLLED_EXCEPTION);
      }
    } catch (Exception err){
      promise.reject(err);
    }
  }


  @ReactMethod
  public void allow(ReadableMap data, final Promise promise) {
    Map parsedData = MapUtil.toMap(data);
    ParcelableNotification notification = Guardian.parseNotification(parsedData);
    try {

      if(enrollment != null) {
        guardian
          .allow(notification, enrollment)
          .start(new Callback<Void>() {
            @Override
            public void onSuccess(Void response) {
              Log.i(TAG, "ALLOWED SUCCESSFULLY");
              promise.resolve(true);
            }

            @Override
            public void onFailure(Throwable exception) {
              Log.e(TAG, "ALLOW FAILED!", exception);
              promise.reject(exception);
            }
          });
      } else {
        promise.reject(DEVICE_NOT_ENROLLED_EXCEPTION);
      }
    } catch (Exception err){
      Log.e(TAG, "ALLOW FAILED!", err);
      promise.reject(err);
    }
  }

  @ReactMethod
  public void reject(ReadableMap data, final Promise promise) {
    try {
      Map parsedData = MapUtil.toMap(data);
      Notification notification = Guardian.parseNotification(parsedData);

      if(enrollment != null) {
        guardian
          .reject(notification, enrollment)
          .start(new Callback<Void>() {
            @Override
            public void onSuccess(Void response) {
              Log.i(TAG, "REJECTED SUCCESSFULLY");
              promise.resolve(true);
            }

            @Override
            public void onFailure(Throwable exception) {
              Log.e(TAG, "REJECT FAILED!", exception);
              promise.reject(exception);
            }
          });
      } else {
        promise.reject(DEVICE_NOT_ENROLLED_EXCEPTION);
      }
    } catch (Exception err){
      Log.e(TAG, "REJECT FAILED!", err);
      promise.reject(err);
    }
  }

  @ReactMethod
  public void unenroll(final Promise promise){
    try {
      if(enrollment != null){
        guardian
          .delete(enrollment)
          .start(new Callback<Void>() {
            @Override
            public void onSuccess(Void response) {
              Log.i(TAG, "UNENROLLED SUCCESSFULLY");
              promise.resolve(true);
            }

            @Override
            public void onFailure(Throwable exception) {
              Log.e(TAG, "UNENROLL FAILED!", exception);
              promise.reject(exception);
            }
          });
      } else {
        promise.reject(DEVICE_NOT_ENROLLED_EXCEPTION);
      }
    } catch (Exception err) {
      Log.e(TAG, "UNENROLL FAILED!", err);
      promise.reject(err);
    }

  }
}