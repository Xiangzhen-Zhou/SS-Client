//
//  HelperTool.h
//  HelperTool
//
//  Created by 周向真 on 2018/4/17.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kHelperToolMachServiceName  @"com.zxzerster.SS-Client.HelperTool"

@protocol HelperToolProtocol

@required

- (void)installNetworkToolAtSourcePath: (NSString *)srcPath withReply: (void(^)(BOOL success, NSString* message, NSError* error))reply;
- (void)setGlobalModeWithReply: (void(^)(BOOL success, NSError* error))reply;
- (void)turnOffProxyWithReply: (void(^)(BOOL success, NSError* error))reply;

@end

@interface HelperTool : NSObject

- (id)init;

- (void)run;

@end
