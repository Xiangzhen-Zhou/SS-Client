//
//  main.m
//  NetworkProxySetter
//
//  Created by 周向真 on 2018/4/10.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ProxySetter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        AuthorizationRef authRef;
//        AuthorizationFlags flags =  kAuthorizationFlagDefaults |
//                                    kAuthorizationFlagExtendRights |
//                                    kAuthorizationFlagInteractionAllowed |
//                                    kAuthorizationFlagPreAuthorize;
//        OSStatus ret = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &authRef);
//        assert(ret == errAuthorizationSuccess);
//        SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, CFSTR("NetworkProxySetter"), NULL, authRef);
//
//        NSString* path = [NSString stringWithFormat:@"/%@", kSCPrefNetworkServices];
//        NSDictionary* networkServicesSets = (NSDictionary *)SCPreferencesPathGetValue(prefRef, (__bridge CFStringRef)path);
//        for (NSString* setKey in networkServicesSets) {
//            NSDictionary* networkPref = networkServicesSets[setKey];
//            NSString* keyPath = [NSString stringWithFormat: @"%@.%@", (__bridge NSString *)kSCEntNetProxies, (__bridge NSString *)kSCPropNetProxiesProxyAutoConfigURLString];
//            NSString* autoconfigUrl = [networkPref valueForKeyPath: keyPath];
//            NSLog(@"AutoconfigURL: %@", autoconfigUrl);
//        }
        
        ProxySetter* proxySetter = [ProxySetter sharedSetter];
        [proxySetter emptyProxies];
    }
    return 0;
}
