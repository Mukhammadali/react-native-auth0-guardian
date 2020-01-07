
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(RNAuth0Guardian, NSObject)


RCT_EXTERN_METHOD(enroll:(NSString *)enrollmentURI deviceToken:(NSString *)deviceToken auth0Domain:(NSString *)auth0Domain callback:(RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(allow:(NSDictionary *)userInfo callback:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(reject:(NSDictionary *)userInfo callback:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(unenroll:(NSString *)deviceToken callback:(RCTResponseSenderBlock)callback)

@end
  
