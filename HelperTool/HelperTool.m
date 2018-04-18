//
//  HelperTool.m
//  HelperTool
//
//  Created by 周向真 on 2018/4/17.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import "HelperTool.h"

#define HelperToolErrorDomain   @"com.zxzerster.SS-Client.HelperTool.error"

#define EPARA       -0x101
#define ESRCFILE    -0x102
#define EDESTFOLDER -0x103
#define ECOPY       -0x104

@interface HelperTool() <NSXPCListenerDelegate, HelperToolProtocol>

@property (strong) NSXPCListener* listener;

@property (copy, readonly) NSString* localLibPath;

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

- (NSString *)localLibPath {
    NSFileManager* fs = [NSFileManager defaultManager];
    return [[[fs URLsForDirectory: NSLibraryDirectory inDomains: NSLocalDomainMask] lastObject] path];
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

// Didn't consider multiprocess environment
- (void)installNetworkToolAtSourcePath: (NSString *)srcPath withReply: (void(^)(BOOL, NSString*, NSError*))reply {
    if (!srcPath || [srcPath length] == 0) {
        NSError* error = [NSError errorWithDomain: HelperToolErrorDomain code: EPARA userInfo: @{NSLocalizedDescriptionKey: @"Source path string is empty"}];
        reply(NO, @"Empty source path string", error);
        return;
    }
    
    NSFileManager* fs = [NSFileManager defaultManager];
    
    if (![fs fileExistsAtPath:srcPath isDirectory: nil]) {
        NSError* error = [NSError errorWithDomain: HelperToolErrorDomain code: ESRCFILE userInfo: @{NSLocalizedDescriptionKey: @"Source file doesn't exist"}];
        reply(NO, @"Source file dones't exist", error);
        return;
    }
    
    NSString* source = [[[self.localLibPath stringByAppendingPathComponent: @"Application Support"] stringByAppendingPathComponent: @"com.zxzerster.SS-Client"] stringByAppendingPathComponent: @"Tools"];
    
    NSError* error;
    if (![fs createDirectoryAtPath: source withIntermediateDirectories: YES attributes: nil error: &error]) {
        NSError* error = [NSError errorWithDomain: HelperToolErrorDomain code: EDESTFOLDER userInfo: @{NSLocalizedDescriptionKey: @"Create destination folder failed"}];
        reply(NO, @"Create destination folder failed", error);
        return;
    }
    
    source = [source stringByAppendingPathComponent: @"NetworkTool"];
    if (![fs moveItemAtPath: srcPath toPath: source error: &error]) {
        //TODO: if failed due to Tool already there, then just continue, no need to error out.
        
        NSError* error = [NSError errorWithDomain: HelperToolErrorDomain code: ECOPY userInfo: @{NSLocalizedDescriptionKey: @"Copy tool failed"}];
        reply(NO, @"Copy tool failed", error);
        return;
    }
    
    reply(YES, [NSString stringWithFormat: @"Network tool copied here: %@", source], nil);
    return;
}

- (void)setGlobalModeWithReply:(void (^)(BOOL, NSError *))reply {
    NSTask* task = [[NSTask alloc] init];
    NSString* launchPath = [[[[self.localLibPath stringByAppendingPathComponent: @"Application Support"] stringByAppendingPathComponent: @"com.zxzerster.SS-Client"] stringByAppendingPathComponent: @"Tools"] stringByAppendingPathComponent: @"NetworkTool"];
    
    task.launchPath = launchPath;
    task.arguments = @[@"-m", @"global", @"-p", @"10086"];

    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    NSFileHandle* readHandle = [pipe fileHandleForReading];
    NSData* ret = [readHandle readDataToEndOfFile];
    NSString* msg = [[NSString alloc] initWithData: ret encoding: NSUTF8StringEncoding];
    
    reply(status == 0 ? YES : NO, nil);
}

- (void)turnOffProxyWithReply:(void (^)(BOOL, NSError *))reply {
    NSTask* task = [[NSTask alloc] init];
    NSString* launchPath = [[[[self.localLibPath stringByAppendingPathComponent: @"Application Support"] stringByAppendingPathComponent: @"com.zxzerster.SS-Client"] stringByAppendingPathComponent: @"Tools"] stringByAppendingPathComponent: @"NetworkTool"];
    
    task.launchPath = launchPath;
    task.arguments = @[@"-m", @"off"];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    [task launch];
    [task waitUntilExit];
    int status = [task terminationStatus];
    
    NSFileHandle* readHandle = [pipe fileHandleForReading];
    NSData* ret = [readHandle readDataToEndOfFile];
    NSString* msg = [[NSString alloc] initWithData: ret encoding: NSUTF8StringEncoding];
    
    reply(status == 0 ? YES : NO, nil);
}

@end
