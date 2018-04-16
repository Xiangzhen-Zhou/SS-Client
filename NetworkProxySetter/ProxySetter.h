//
//  ProxySetter.h
//  NetworkProxySetter
//
//  Created by 周向真 on 2018/4/12.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProxySetter : NSObject

+ (id)sharedSetter;

/** Caller should gurantee saveProxies and restoreProxies are called in pair */
// Save current proxies data into file
- (BOOL)saveProxies;
// Restore proxies settings from previous saved file
- (BOOL)restoreProxies;
- (void)emptyProxies;

- (void)setProxyForProtocol:(NSString *)protocol Enabled:(BOOL)enabled Url:(NSString *)urlString Port:(NSUInteger)port;
- (void)setExceptionList: (NSArray *)exceptionList;
- (void)setPacEnabled: (BOOL)enabled UrlString:(NSString *)pacUrlString;

@end
