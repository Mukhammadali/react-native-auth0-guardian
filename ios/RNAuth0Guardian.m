
#import "RNAuth0Guardian.h"

@implementation RNAuth0Guardian

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXTERN_METHOD(enroll:(NSString *)enrollmentURI deviceToken:(NSString *)deviceToken auth0Domain:(NSString *)auth0Domain)

RCT_EXTERN_METHOD(allow:(NSDictionary *)userInfo)
RCT_EXTERN_METHOD(reject:(NSDictionary *)userInfo)
RCT_EXTERN_METHOD(unenroll:(NSString *)deviceToken)

@end
  
