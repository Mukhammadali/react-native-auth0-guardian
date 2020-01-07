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


@objc(RNAuth0Guardian)
class RNAuth0Guardian: NSObject {
  var signingKey: KeychainRSAPrivateKey?
  
  override init() {
    super.init()
    do {
        self.signingKey = try KeychainRSAPrivateKey.new(with: "org.reactjs.native.example.PortalNow")
    }
    catch {
      fatalError("Error in signingKey generation")
    }
  }
  
  
  @objc
    func enroll(_ enrollmentURI: NSString, deviceToken: NSString, auth0Domain: NSString, callback: @escaping RCTResponseSenderBlock){
    let enrollmentUri = enrollmentURI as String
    let deviceTokenString = deviceToken as String
    let domain = auth0Domain as String
    
    do {
      let verificationKey = try signingKey!.verificationKey()
      
      if (deviceTokenString.isEmpty) {
        print("DEVICE_TOKEN is not provided!")
      } else if (enrollmentUri.isEmpty) {
        print("ENROLLMENT_URI is not provided!")
      } else {
        Guardian
        .enroll(forDomain: domain,
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
              UserDefaults.standard.save(customObject: clonedData, inKey: "ENROLLED_DEVICE")
              UserDefaults.standard.set(domain, forKey: "AUTH0_DOMAIN")
              callback([NSNull(), enrolledDevice.id])
              break
            case .failure(let cause):
              print("ENROLL FAILED: ", cause)
              callback([cause, NSNull()])
              break
            }
        }
      }
    } catch {
      fatalError("Something went wrong in Enroll method ;( !")
    }
  }
  
  @objc
  func allow(_ userInfo: NSDictionary, callback: @escaping RCTResponseSenderBlock){
    let domain = UserDefaults.standard.value(forKey: "AUTH0_DOMAIN") as! String
    let retrievedData = UserDefaults.standard.retrieve(object: CustomEnrolledDevice.self, fromKey: "ENROLLED_DEVICE")!
    let enrolledDevice = EnrolledDevice(id: retrievedData.id, userId: retrievedData.userId, deviceToken: retrievedData.deviceToken, notificationToken: retrievedData.notificationToken, signingKey: self.signingKey!, totp: retrievedData.totp
    )
    if let notification = Guardian.notification(from: userInfo as! [AnyHashable : Any]) {
      Guardian
      .authentication(forDomain: domain, device: enrolledDevice)
      .allow(notification: notification)
      .start { result in
          switch result {
          case .success:
            print("ALLOWED SUCCESSFULY!")
            callback([NSNull(), true])
            break
          case .failure(let cause):
            print("ALLOW FAILED!", cause)
            callback([cause, NSNull()])
            break
          }
      }
    }
  }
  
  @objc
    func reject(_ userInfo: [AnyHashable : Any], callback: @escaping RCTResponseSenderBlock) {
      let domain = UserDefaults.standard.value(forKey: "AUTH0_DOMAIN") as! String
      let retrievedData = UserDefaults.standard.retrieve(object: CustomEnrolledDevice.self, fromKey: "ENROLLED_DEVICE")!
      let enrolledDevice = EnrolledDevice(id: retrievedData.id, userId: retrievedData.userId, deviceToken: retrievedData.deviceToken, notificationToken: retrievedData.notificationToken, signingKey: self.signingKey!, totp: retrievedData.totp
      )
     if let notification = Guardian.notification(from: userInfo) {
       Guardian
         .authentication(forDomain: domain, device: enrolledDevice)
         .reject(notification: notification)
         .start { result in
             switch result {
             case .success:
               print("REJECTED SUCCESSFULLY!")
               callback([NSNull(), true])
               break
             case .failure(let cause):
               print("REJECT FAILED!", cause)
               callback([cause, NSNull()])
               break
             }
       }
     }
   }
  
  @objc
  func unenroll(_ deviceToken: NSString, callback: @escaping RCTResponseSenderBlock) {
    let domain = UserDefaults.standard.value(forKey: "AUTH0_DOMAIN") as! String
    let retrievedData = UserDefaults.standard.retrieve(object: CustomEnrolledDevice.self, fromKey: "ENROLLED_DEVICE")!
    let enrolledDevice = EnrolledDevice(id: retrievedData.id, userId: retrievedData.userId, deviceToken: retrievedData.deviceToken, notificationToken: retrievedData.notificationToken, signingKey: self.signingKey!, totp: retrievedData.totp
    )
    Guardian
    .api(forDomain: domain)
      .device(forEnrollmentId: enrolledDevice.id, token: enrolledDevice.deviceToken)
    .delete()
    .start { result in
        switch result {
        case .success:
          print("UNENROLLED SUCCESSFULLY!")
          callback([NSNull(), true])
          break
        case .failure(let cause):
          print("UNENROLL FAILED!", cause)
          callback([cause, NSNull()])
          break
        }
    }
  }
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

