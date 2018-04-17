//
//  HelperTool.m
//  HelperTool
//
//  Created by 周向真 on 2018/4/17.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import "HelperTool.h"

@interface HelperTool() <NSXPCListenerDelegate, HelperToolProtocol>

@property (strong) NSXPCListener* listener;

@end

@implementation HelperTool

- (id)init {
    self = [super init];
    if (self) {
        _listener = [[NSXPCListener alloc] initWithMachServiceName: kHelperToolMachServiceName];
        _listener.delegate = self;
    }
    
    return self;
}

- (void)run {
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
#pragma unused (listener)
    assert(listener == self.listener);
    assert(newConnection);
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol: @protocol(HelperToolProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (void)installProxySetterAtPath:(NSString *)installPath withReply:(void (^)(BOOL, NSString *, NSError *))reply {
    reply(NO, @"Message from HelperTool", nil);
}

@end
