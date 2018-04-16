//
//  ProxySetter.m
//  NetworkProxySetter
//
//  Created by 周向真 on 2018/4/12.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

#import "ProxySetter.h"

#define SAVED_PROXIES_FILE  @"saved-proxies.plist"

@interface ProxySetter() {
    AuthorizationRef _authRef;
    SCPreferencesRef _prefRef;
}

@property (copy, readonly) NSString *configsSavedFolder;

@end

@implementation ProxySetter

+ (id)sharedSetter {
    static ProxySetter* setter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        setter = [[ProxySetter alloc] init];
    });
    
    return setter;
}

- (id)init {
    self = [super init];
    
    if (self) {
        AuthorizationFlags flags = kAuthorizationFlagPreAuthorize
        | kAuthorizationFlagDefaults
        | kAuthorizationFlagExtendRights
        | kAuthorizationFlagInteractionAllowed;
        
        OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &self->_authRef);
        if (status != errAuthorizationSuccess) {
            assert(NO);
            return nil;
        }
        
        self->_prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, CFSTR("NetworkProxySetter"), NULL, self->_authRef);
        if (!self->_prefRef) {
            assert(NO);
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    AuthorizationFree(self->_authRef, kAuthorizationFlagDefaults);
    CFRelease(self->_prefRef);
}

- (NSString *)configsSavedFolder {
    NSString* path = [[[[NSFileManager defaultManager] URLsForDirectory: NSLibraryDirectory inDomains: NSUserDomainMask] lastObject] path];
    path = [[[path stringByAppendingPathComponent: @"Application Support"] stringByAppendingPathComponent: @"com.zxzerster.SS-Client"] stringByAppendingPathComponent: @"configs"];
    
    return path;
}

- (BOOL)saveProxies {
    NSMutableDictionary* saved = [NSMutableDictionary new];
    [self enumerateProxies:^(NSString* set, NSDictionary* proxy) {
        saved[set] = proxy;
    }];
    
    NSFileManager* fs = [NSFileManager defaultManager];
    NSError* error;
    if (![fs createDirectoryAtPath: self.configsSavedFolder withIntermediateDirectories: YES attributes: NULL error: &error]) {
        NSLog(@"Save proxies failed: %@", [error localizedDescription]);
        return NO;
    }
    
    NSString* savedPath = [self.configsSavedFolder stringByAppendingPathComponent: SAVED_PROXIES_FILE];
    BOOL ret = [saved writeToFile: savedPath atomically: YES];
    
    NSLog(@"Proxies saved: %d", ret);
    return ret;
}

- (BOOL)restoreProxies {
    NSString* filePath = [self.configsSavedFolder stringByAppendingPathComponent: SAVED_PROXIES_FILE];
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath: filePath];
    
    if (existed) {
        NSDictionary* proxies = [NSDictionary dictionaryWithContentsOfFile: filePath];
        [self enumerateProxies:^(NSString* set, NSDictionary* proxy) {
            NSString* path = [NSString stringWithFormat: @"/%@/%@/%@", kSCPrefNetworkServices, set, kSCEntNetProxies];
            BOOL ret = SCPreferencesPathSetValue(self->_prefRef, (__bridge CFStringRef)path, (__bridge CFDictionaryRef)proxies[set]);
            assert(ret);
        }];
        
        SCPreferencesCommitChanges(self->_prefRef);
        SCPreferencesApplyChanges(self->_prefRef);
        SCPreferencesSynchronize(self->_prefRef);
        
        return YES;
    } else {
        return NO;
    }
}

- (void)emptyProxies {
    // For now, only PAC / HTTP / HTTPS / SCOKS proxy setting will be emptied
    NSDictionary* empty = @{
            // PAC
            (NSString *)kSCPropNetProxiesProxyAutoConfigEnable: [NSNumber numberWithInteger: 0],
            (NSString *)kSCPropNetProxiesProxyAutoConfigURLString: @"",
            // HTTP
            (NSString *)kSCPropNetProxiesHTTPEnable: [NSNumber numberWithInteger: 0],
            (NSString *)kSCPropNetProxiesHTTPProxy: @"",
            (NSString *)kSCPropNetProxiesHTTPPort: [NSNumber numberWithInt: 0],
            // HTTPS
            (NSString *)kSCPropNetProxiesHTTPSEnable: [NSNumber numberWithInteger: 0],
            (NSString *)kSCPropNetProxiesHTTPSProxy: @"",
            (NSString *)kSCPropNetProxiesHTTPSPort: [NSNumber numberWithInt: 0],
            // SOCKS
            (NSString *)kSCPropNetProxiesSOCKSEnable: [NSNumber numberWithInt: 0],
            (NSString *)kSCPropNetProxiesSOCKSProxy: @"",
            (NSString *)kSCPropNetProxiesSOCKSPort: [NSNumber numberWithInt: 0],
            // Exception list
            (NSString *)kSCPropNetProxiesExceptionsList: @[]
    };
    
    [self enumerateProxies:^(NSString* set, NSDictionary* proxy) {
        NSString* path = [NSString stringWithFormat: @"/%@/%@/%@", kSCPrefNetworkServices, set, kSCEntNetProxies];
        BOOL ret = SCPreferencesPathSetValue(self->_prefRef, (__bridge CFStringRef)path, (__bridge CFDictionaryRef)empty);
        assert(ret);
    }];
    
    SCPreferencesCommitChanges(self->_prefRef);
    SCPreferencesApplyChanges(self->_prefRef);
    SCPreferencesSynchronize(self->_prefRef);
}

- (void)enumerateProxies: (void(^)(NSString*, NSDictionary*))block {
    NSDictionary* sets = SCPreferencesGetValue(self->_prefRef, kSCPrefNetworkServices);
    for (NSString* key in sets.allKeys) {
        NSDictionary* proxies = ((NSDictionary *)sets[key])[(__bridge NSString *)kSCEntNetProxies];
        block(key, proxies);
    }
}

- (void)setProxyForProtocol:(NSString *)protocol Enabled:(BOOL)enabled Url:(NSString *)urlString Port:(NSUInteger)port {
    if ([protocol isEqualToString: @"Http"]) {
        [self setHttpProxyProtocolEnabled: enabled Url: urlString Port: port];
    } else if ([protocol isEqualToString: @"Https"]) {
        [self setHttpsProxyProtocolEnabled: enabled Url: urlString Port: port];
    } else if ([protocol isEqualToString: @"Socks"]) {
        [self setSocksProxyProtocolEnabled: enabled Url: urlString Port: port];
    } else {
        // Not a correct protocol string
        assert(NO);
    }
}

- (void)setNetworkProxySetting: (NSDictionary *)newSetting {
    [self enumerateProxies:^(NSString* set, NSDictionary* proxy) {
        NSMutableDictionary* setting = [NSMutableDictionary dictionaryWithDictionary: proxy];
        for (NSString* key in newSetting.allKeys) {
            setting[key] = newSetting[key];
        }
        
        NSString* path = [NSString stringWithFormat: @"/%@/%@/%@", kSCPrefNetworkServices, set, kSCEntNetProxies];
        BOOL ret = SCPreferencesPathSetValue(self->_prefRef, (__bridge CFStringRef)path, (__bridge CFDictionaryRef)setting);
        assert(ret);
    }];
    
    SCPreferencesCommitChanges(self->_prefRef);
    SCPreferencesApplyChanges(self->_prefRef);
    SCPreferencesSynchronize(self->_prefRef);
}

- (void)setHttpProxyProtocolEnabled:(BOOL)enabled Url: (NSString *)urlString Port: (NSUInteger)port {
    NSMutableDictionary* setting = [NSMutableDictionary dictionary];
    setting[(NSString *)kSCPropNetProxiesHTTPEnable] = [NSNumber numberWithInt: enabled ? 1 : 0];
    if (enabled) {
        setting[(NSString *)kSCPropNetProxiesHTTPProxy] =  urlString;
        setting[(NSString *)kSCPropNetProxiesHTTPPort] = [NSNumber numberWithInteger: port];
    }
    
    [self setNetworkProxySetting: setting];
}

- (void)setHttpsProxyProtocolEnabled:(BOOL)enabled Url: (NSString *)urlString Port: (NSUInteger)port {
    NSMutableDictionary* setting = [NSMutableDictionary dictionary];
    setting[(NSString *)kSCPropNetProxiesHTTPSEnable] = [NSNumber numberWithInt: enabled ? 1 : 0];
    if (enabled) {
        setting[(NSString *)kSCPropNetProxiesHTTPSProxy] =  urlString;
        setting[(NSString *)kSCPropNetProxiesHTTPSPort] = [NSNumber numberWithInteger: port];
    }
    
    [self setNetworkProxySetting: setting];
}

- (void)setSocksProxyProtocolEnabled:(BOOL)enabled Url: (NSString *)urlString Port: (NSUInteger)port {
    NSMutableDictionary* setting = [NSMutableDictionary dictionary];
    setting[(NSString *)kSCPropNetProxiesSOCKSEnable] = [NSNumber numberWithInt: enabled ? 1 : 0];
    if (enabled) {
        setting[(NSString *)kSCPropNetProxiesSOCKSProxy] =  urlString;
        setting[(NSString *)kSCPropNetProxiesSOCKSPort] = [NSNumber numberWithInteger: port];
    }
    
    [self setNetworkProxySetting: setting];
}

- (void)setExceptionList:(NSArray *)exceptionList {
    if (!exceptionList || exceptionList.count == 0) {
        return;
    }
    
    NSDictionary* setting = @{(NSString *)kSCPropNetProxiesExceptionsList: exceptionList};
    [self setNetworkProxySetting: setting];
}

- (void)setPacEnabled: (BOOL)enabled UrlString:(NSString *)pacUrlString {
    if (enabled && (!pacUrlString || [pacUrlString isEqualToString: @""])) {
        return;
    }
    
    NSDictionary* setting = @{
                              (NSString *)kSCPropNetProxiesProxyAutoConfigEnable: [NSNumber numberWithInteger: enabled ? 1 : 0],
                              (NSString *)kSCPropNetProxiesProxyAutoConfigURLString: enabled ? pacUrlString : @""
                              };
    
    [self setNetworkProxySetting: setting];
}

@end
