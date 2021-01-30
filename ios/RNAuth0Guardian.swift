//
//  RNAuth0Guardian.swift
//  RNAuth0Guardian
//
//  Created by Mukhammad Ali on 2020/01/07.
//  Copyright © 2020. All rights reserved.
//

import Guardian

struct CustomEnrolledDevice: Codable {
  public let id: String
  public let userId: String
  public let deviceToken: String
  public let notificationToken: String
  public let totp: OTPParameters?

  public init(
       id: String,
       userId: String,
       deviceToken: String,
       notificationToken: String,
       totp: OTPParameters? = nil
      ) {
      self.id = id
      self.userId = userId
      self.deviceToken = deviceToken
      self.notificationToken = notificationToken
      self.totp = totp
  }
  enum CodingKeys: String, CodingKey {
      case id
      case userId
      case deviceToken
      case notificationToken
      case totp
  }

  init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      userId = try container.decode(String.self, forKey: .userId)
      deviceToken = try container.decode(String.self, forKey: .deviceToken)
      notificationToken = try container.decode(String.self, forKey: .notificationToken)
      totp = try container.decode(OTPParameters.self, forKey: .totp)
  }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(userId, forKey: .userId)
      try container.encode(deviceToken, forKey: .deviceToken)
      try container.encode(notificationToken, forKey: .notificationToken)
      try container.encode(totp, forKey: .totp)
    }
}

extension UserDefaults {
   func save<T:Encodable>(customObject object: T, inKey key: String) {
       let encoder = JSONEncoder()
       if let encoded = try? encoder.encode(object) {
           self.set(encoded, forKey: key)
       }
   }
   func retrieve<T:Decodable>(object type:T.Type, fromKey key: String) -> T? {
       if let data = self.data(forKey: key) {
           let decoder = JSONDecoder()
           if let object = try? decoder.decode(type, from: data) {
               return object
           }else {
               print("Couldnt decode object")
               return nil
           }
       }else {
           print("Couldnt find key")
           return nil
       }
   }
}


enum CustomError: Error {
    case runtimeError(String)
}


@objc(RNAuth0Guardian)
class RNAuth0Guardian: NSObject {
    let AUTH0_DOMAIN = "AUTH0_DOMAIN"
    let ENROLLED_DEVICE = "ENROLLED_DEVICE"
    
    var domain: String?
    var enrolledDevice: EnrolledDevice?
    var signingKey: KeychainRSAPrivateKey?
    
  
    override init() {
        super.init()
    }
    @objc
    func initialize(_ auth0Domain: NSString,  resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        let domain = auth0Domain as String
        let bundleID = Bundle.main.bundleIdentifier
        if domain.isEmpty {
            reject("DOMAIN_NULL", "Domain is null", nil)
        } else {
            self.domain = auth0Domain as String
            do {
                let signingKey = try KeychainRSAPrivateKey.new(with: bundleID!)
                self.signingKey = signingKey
                 if let retrievedData = UserDefaults.standard.retrieve(object: CustomEnrolledDevice.self, fromKey: ENROLLED_DEVICE) ?? nil {
                     let enrolledDevice = EnrolledDevice(id: retrievedData.id, userId: retrievedData.userId, deviceToken: retrievedData.deviceToken, notificationToken: retrievedData.notificationToken, signingKey: signingKey, totp: retrievedData.totp
                        )
                     self.enrolledDevice = enrolledDevice;
                     
                 }
                
                resolve(true)
            } catch {
                reject("SIGNING_KEY", "SigningKey generation failed", error)
            }
        }
    }
    @objc
    func getTOTP(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock){
        if (self.enrolledDevice != nil) {
            let totpInt: Int = try! Guardian.totp(parameters: self.enrolledDevice!.totp!).code();
            var totpString = String(totpInt)
            if(totpString.isEmpty == false && totpString.count <= 5) {
                for _ in 1...6 - totpString.count {
                    totpString = "0" + totpString
                }
            }
            resolve(totpString)
        } else {
            reject("DEVICE_NOT_ENRROLED", "Device is not enrolled yet!", nil)
        }
    }
  
    @objc
    func enroll(_ enrollmentURI: NSString, deviceToken: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock){
        let enrollmentUri = enrollmentURI as String
        let deviceTokenString = deviceToken as String
        do {
          let verificationKey = try signingKey!.verificationKey()
          
          if (deviceTokenString.isEmpty) {
            reject("DEVICE_TOKEN_NULL", "Device token is not provided", nil)
          } else if (enrollmentUri.isEmpty) {
            reject("ENROLLMENT_URI_NULL", "Enrollment URI from Qrcode is not provided", nil)
          } else {
            Guardian
                .enroll(forDomain: self.domain!,
                    usingUri: enrollmentUri,
                    notificationToken: deviceTokenString,
                    signingKey: signingKey!,
                    verificationKey: verificationKey
                    )
            .start { result in
                switch result {
                case .success(let enrolledDevice):
                    self.enrolledDevice = enrolledDevice;
                    let clonedData = CustomEnrolledDevice(id: enrolledDevice.id, userId: enrolledDevice.userId, deviceToken: enrolledDevice.deviceToken, notificationToken: enrolledDevice.notificationToken, totp: enrolledDevice.totp
                    )
                    UserDefaults.standard.save(customObject: clonedData, inKey: self.ENROLLED_DEVICE)

                    resolve(enrolledDevice.totp?.base32Secret)
                    break
                case .failure(let cause):
                    print("ENROLL FAILED: ", cause)
                    reject("ENROLLMENT_FAILED", "Enrollment failed", cause)
                    break
                }
            }
          }
        } catch {
            reject("ENROLLMENT_FAILED", "Enrollment failed", error)
        }
    }
  
    @objc
    func allow(_ userInfo: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock){
        if (self.enrolledDevice != nil) {
            if let notification = Guardian.notification(from: userInfo as! [AnyHashable : Any]) {
              Guardian
                .authentication(forDomain: self.domain!, device: self.enrolledDevice!)
                .allow(notification: notification)
                .start { result in
                  switch result {
                  case .success:
                    resolve(true)
                    break
                  case .failure(let cause):
                    print("ALLOW FAILED!", cause)
                    reject("ALLOW_FAILED", "Allow failed", cause)
                    break
                  }
                }
            } else {
                 reject("NOTIFICATION_NULL", "Notification is not provided yet!", nil)
            }
        } else {
            reject("DEVICE_NOT_ENRROLED", "Device is not enrolled yet!", nil)
        }
    }
  
    @objc
    func reject(_ userInfo: [AnyHashable : Any], resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if let notification = Guardian.notification(from: userInfo) {
            Guardian
                .authentication(forDomain: self.domain!, device: self.enrolledDevice!)
                .reject(notification: notification)
                .start { result in
                     switch result {
                         case .success:
                           resolve(true)
                           break
                         case .failure(let cause):
                           print("REJECT FAILED!", cause)
                           reject("REJECT_FAILED", "Reject failed!" ,cause)
                           break
                     }
                }
        } else {
             reject("NOTIFICATION_NULL", "Notification is not provided yet!", nil)
        }
    }
  
    @objc
    func unenroll(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Guardian
            .api(forDomain: self.domain!)
            .device(forEnrollmentId: self.enrolledDevice!.id, token: self.enrolledDevice!.deviceToken)
            .delete()
            .start { result in
                switch result {
                case .success:
                  resolve(true)
                  break
                case .failure(let cause):
                  print("UNENROLL FAILED!", cause)
                  reject("UNENROLL_FAILED", "Unenroll failed!", cause)
                  break
                }
            }
    }
  
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

