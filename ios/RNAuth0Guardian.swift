//
//  RNAuth0Guardian.swift
//  RNAuth0Guardian
//
//  Created by Mukhammad Ali on 2020/01/07.
//  Copyright © 2020 Facebook. All rights reserved.
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
    let ENROLLED_DEVICE_NULL_ERROR: CustomError = CustomError.runtimeError(<#T##String#>)
    
    var domain: String?
    let enrolledDevice: EnrolledDevice?
    var signingKey: KeychainRSAPrivateKey?
    
  
    override init() {
        super.init()
    }
    @objc
    func initialize(_ auth0Domain: NSString, resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        let domain = auth0Domain as String
        if domain.isEmpty {
            reject(Error("DOMAIN_NULL"))
        } else {
            self.domain = auth0Domain as String
            let signingKey = try KeychainRSAPrivateKey.new(with: "org.reactjs.native.example.PortalNow")!
            self.signingKey = signingKey
            if let retrievedData = UserDefaults.standard.retrieve(object: CustomEnrolledDevice.self, fromKey: ENROLLED_DEVICE) ?? nil {
                let enrolledDevice = EnrolledDevice(id: retrievedData.id, userId: retrievedData.userId, deviceToken: retrievedData.deviceToken, notificationToken: retrievedData.notificationToken, signingKey: signingKey, totp: retrievedData.totp
                   )
                self.enrolledDevice = enrolledDevice;
                
            }
           
            resolve(true)
        }
    }
    
    @objc
    func getTOTP(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock){
        do {
            if (self.enrolledDevice != nil) {
                let totp: TOTP = try! Guardian.totp(parameters: self.enrolledDevice.totp)
                resolve(totp)
            }
            
        } catch {
            reject(error)
        }
    }
  
    @objc
    func enroll(_ enrollmentURI: NSString, deviceToken: NSString, resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock){
        let enrollmentUri = enrollmentURI as String
        let deviceTokenString = deviceToken as String
        
        do {
          let verificationKey = try signingKey!.verificationKey()
          
          if (deviceTokenString.isEmpty) {
            reject(Error("DEVICE_TOKEN_NULL"))
          } else if (enrollmentUri.isEmpty) {
            reject(Error("ENROLLMENT_URI_NULL"))
          } else {
            Guardian
                .enroll(forDomain: self.domain,
                    usingUri: enrollmentUri,
                    notificationToken: deviceTokenString,
                    signingKey: signingKey!,
                    verificationKey: verificationKey
                    )
            .start { result in
                switch result {
                case .success(let enrolledDevice):
                  let clonedData = CustomEnrolledDevice(id: enrolledDevice.id, userId: enrolledDevice.userId, deviceToken: enrolledDevice.deviceToken, notificationToken: enrolledDevice.notificationToken, totp: enrolledDevice.totp
                  )
                  UserDefaults.standard.save(customObject: clonedData, inKey: ENROLLED_DEVICE)
                  resolve(enrolledDevice.totp?.base32Secret)
                  break
                case .failure(let cause):
                  print("ENROLL FAILED: ", cause)
                 reject(cause)
                  break
                }
            }
          }
        } catch {
          reject(error)
        }
    }
  
    @objc
    func allow(_ userInfo: NSDictionary, resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock){
        do {
            if (self.enrolledDevice != nil) {
                if let notification = Guardian.notification(from: userInfo as! [AnyHashable : Any]) {
                  Guardian
                    .authentication(forDomain: self.domain, device: self.enrolledDevice)
                    .allow(notification: notification)
                    .start { result in
                      switch result {
                      case .success:
                        print("ALLOWED SUCCESSFULY!")
                        resolve(true)
                        break
                      case .failure(let cause):
                        print("ALLOW FAILED!", cause)
                        reject(cause)
                        break
                      }
                    }
                }
            } else {
                reject(ENROLLED_DEVICE_NULL_ERROR)
            }
            
        } catch {
            reject(error)
        }
    }
  
    @objc
    func reject(_ userInfo: [AnyHashable : Any], resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        do {
            if let notification = Guardian.notification(from: userInfo) {
                Guardian
                    .authentication(forDomain: self.domain, device: self.enrolledDevice)
                    .reject(notification: notification)
                    .start { result in
                         switch result {
                             case .success:
                               print("REJECTED SUCCESSFULLY!")
                               resolve(true)
                               break
                             case .failure(let cause):
                               print("REJECT FAILED!", cause)
                               reject(cause)
                               break
                         }
                    }
            }
        } catch {
            reject(error)
        }
    }
  
    @objc
    func unenroll(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        do {
            Guardian
                .api(forDomain: self.domain)
                .device(forEnrollmentId: self.enrolledDevice.id, token: self.enrolledDevice.token)
                .delete()
                .start { result in
                    switch result {
                    case .success:
                      print("UNENROLLED SUCCESSFULLY!")
                      resolve(true)
                      break
                    case .failure(let cause):
                      print("UNENROLL FAILED!", cause)
                      reject(cause)
                      break
                    }
                }
        } catch {
            reject(error)
        }
    }
  
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

