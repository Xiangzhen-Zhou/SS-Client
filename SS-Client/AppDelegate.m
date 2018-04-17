//
//  AppDelegate.m
//  SS-Client
//
//  Created by 周向真 on 2018/4/9.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "AppDelegate.h"
#import "HelperTool.h"

#define STARTUP_LOGIN   0

@interface AppDelegate () {
    NSStatusItem* _statusItem;
    AuthorizationRef _authRef;
    NSXPCConnection* _xpcConnection;
}

@property (weak) IBOutlet NSMenu *menu;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed;
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &_authRef);
    assert(status == errAuthorizationSuccess);
    
    CFErrorRef error;
    BOOL ret = SMJobBless(kSMDomainSystemLaunchd, CFSTR("com.zxzerster.SS-Client.HelperTool"), _authRef, &error);
    if (!ret) {
        NSLog(@"SMJobBless failed: %@", [((__bridge NSError *)error) localizedDescription]);
        assert(NO);
        exit(EXIT_FAILURE);
    }
    
    _xpcConnection = [[NSXPCConnection alloc] initWithMachServiceName: kHelperToolMachServiceName options: NSXPCConnectionPrivileged];
    _xpcConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol: @protocol(HelperToolProtocol)];
    _xpcConnection.invalidationHandler = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"++++++++++   Error here!");
        });
    };
    
    //----------   Test code
    [_xpcConnection resume];
    NSLog(@"Calling remote object...");
    [[_xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"==========   error handler here!");
    }] installProxySetterAtPath: @"Install Tool Path" withReply:^(BOOL success, NSString* msg, NSError* error) {
        NSLog(@"==========    Message: %@", msg);
    }];
    NSLog(@"Calling finished");
    //----------   Test code
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];
    NSImage* statusItemIcon = [NSImage imageNamed: @"MenuIcon"];
    statusItemIcon.template = YES;
    _statusItem.image = statusItemIcon;
    _statusItem.menu = self->_menu;

    for (int index = 0; index < [self.menu numberOfItems]; index++) {
        [self updateMenuItemAtIndex: index];
    }
    
    [self tryTerminatedLaunchHelper];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    AuthorizationFree(_authRef, kAuthorizationFlagDefaults);
}

- (IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate: nil];
}

- (IBAction)startupAtLogin:(id)sender {
    BOOL startup = [[NSUserDefaults standardUserDefaults] boolForKey: @"START_UP_AT_LOGIN"];
    startup = !startup;
    [[NSUserDefaults standardUserDefaults] setBool: startup forKey: @"START_UP_AT_LOGIN"];
    BOOL ret = SMLoginItemSetEnabled(CFSTR("com.zxzetster.LaunchHelperTool"), startup);
    assert(ret);
    
    
    [self updateMenuItemAtIndex: STARTUP_LOGIN];
}

- (void)updateMenuItemAtIndex: (NSUInteger)index {
    NSString* menuItemTile;
    NSMenuItem* item = [self.menu itemAtIndex: index];
    switch (index) {
        case STARTUP_LOGIN: {
                BOOL startup = [[NSUserDefaults standardUserDefaults] boolForKey: @"START_UP_AT_LOGIN"];
                menuItemTile = startup ? @"Disable Startup at Login" : @"Enable Startup at Login";
                item.title = menuItemTile;
            }
            break;
            
        default:
            break;
    }
}

- (void)tryTerminatedLaunchHelper {
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSArray* runningApps = [ws runningApplications];
    BOOL running = NO;
    for (NSRunningApplication* app in runningApps) {
        if ([[app bundleIdentifier] isEqualToString: @"com.zxzetster.LaunchHelperTool"]) {
            running = YES;
        }
    }
    
    if (running) {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: @"LaunchHelper_Termination" object: [NSBundle mainBundle].bundleIdentifier];
    }
}

- (BOOL)setStartupAtLogin:(BOOL)enabled {
    BOOL startupAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey: @"START_UP_AT_LOGIN"];
    if (enabled == startupAtLogin) {
        return YES;
    }
    
    BOOL ret = SMLoginItemSetEnabled(CFSTR("com.zxzetster.LaunchHelperTool"), enabled);
    [[NSUserDefaults standardUserDefaults] setBool: enabled forKey: @"START_UP_AT_LOGIN"];
    NSString* menuItemTitle = enabled ? @"Disable Startup at Login" : @"Enable Startup at Login";
    [[self->_menu itemAtIndex: 0] setTitle: menuItemTitle];
    
    [self tryTerminatedLaunchHelper];
    
    return ret;
}

@end
