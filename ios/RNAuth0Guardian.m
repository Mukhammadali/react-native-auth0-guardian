
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(RNAuth0Guardian, NSObject)


RCT_EXTERN_METHOD(enroll:(NSString *)enrollmentURI deviceToken:(NSString *)deviceToken auth0Domain:(NSString *)auth0Domain resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(initialize:(NSString *)auth0Domain)

RCT_EXTERN_METHOD(allow:(NSDictionary *)userInfo resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(reject:(NSDictionary *)userInfo resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(unenroll:(NSString *)deviceToken resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

@end
  
