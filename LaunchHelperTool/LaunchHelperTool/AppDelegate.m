//
//  AppDelegate.m
//  LaunchHelperTool
//
//  Created by 周向真 on 2018/4/9.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(quit) name: @"LaunchHelper_Termination" object: nil];
    
    [self launchMainApp];
    [self quit];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)launchMainApp {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    
    BOOL running = NO;
    running = [ws launchApplication: @"Application/SS-Client.app"];
    // 2nd try
    if (!running) {
        running = [ws launchApplication: @"SS-Client.app"];
    }
    
    if (!running) {
        NSArray* pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
        pathComponents = [pathComponents subarrayWithRange: NSMakeRange(0, pathComponents.count - 1)];
        NSString* launchPath = [[NSString pathWithComponents: pathComponents] stringByAppendingPathComponent: @"SS-Client.app"];
        assert([ws launchApplication: launchPath]);
    }
    
}

- (void)quit {
    [[NSApplication sharedApplication] terminate: nil];
}

@end
