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

@end
