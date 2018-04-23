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
}

@property (weak) IBOutlet NSMenu *menu;
@property (strong, readonly) NSXPCConnection* xpcConnection;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed;
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, flags, &_authRef);
    assert(status == errAuthorizationSuccess);
    
    // SMJobBless will return YES if HelperTool is already there.
    CFErrorRef error;
    BOOL ret = SMJobBless(kSMDomainSystemLaunchd, CFSTR("com.zxzerster.SS-Client.HelperTool"), _authRef, &error);
    if (!ret) {
        NSLog(@"SMJobBless failed: %@", [((__bridge NSError *)error) localizedDescription]);
        assert(NO);
        exit(EXIT_FAILURE);
    }

    [self installNetworkTool];
    
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

- (IBAction)turnOff:(id)sender {
    NSLog(@"User click Turn off menu item");
    [[self.xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        // TODO: Show some error info to user
    }] turnOffProxyWithReply:^(BOOL success, NSError *error) {
        if (!success) {
            // TODO: Show some error info to user
            return;
        }
        
        NSLog(@"Turned off proxy setting");
    }];
}

- (IBAction)globalMode:(id)sender {
    NSLog(@"User click global mode menu item");
    [[self.xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        // TODO: Show some error info to user
    }] setGlobalModeWithReply:^(BOOL success, NSError *error) {
        if (!success) {
            // TODO: Show some error info to user
            return;
        }
        
        NSLog(@"Global network proxy set successfully");
    }];
}

- (IBAction)pacMode:(id)sender {
    NSLog(@"User click pac mode menu item");
    [[self.xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        // TODO: Show some error info to user
    }] setPacModeWithReply:^(BOOL success, NSError *error) {
        if (!success) {
            // TODO: Show some error info to user
            return;
        }
        
        NSLog(@"Pac network proxy set successfully");
    }];
}

- (NSXPCConnection *)xpcConnection {
    static NSXPCConnection* connection;
    if (!connection) {
        connection = [[NSXPCConnection alloc] initWithMachServiceName: kHelperToolMachServiceName options: NSXPCConnectionPrivileged];
        connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol: @protocol(HelperToolProtocol)];
        connection.invalidationHandler = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: figure out what's the purpose of thie handler and add invalidation handler here.
            });
        };
        
        [connection resume];
    }
    
    return connection;
}

- (void)installNetworkTool {
    // Install network tool only if it's not there
    NSFileManager* fs = [NSFileManager defaultManager];
    NSString* localLibPath = [[[fs URLsForDirectory: NSLibraryDirectory inDomains: NSLocalDomainMask] lastObject] path];
    
    NSString* toolPath = [[[[localLibPath stringByAppendingPathComponent: @"Application Support"] stringByAppendingPathComponent: @"com.zxzerster.SS-Client"] stringByAppendingPathComponent: @"Tools"] stringByAppendingPathComponent: @"NetworkTool"];
    if (![fs fileExistsAtPath: toolPath isDirectory: nil]) {
        // Let's install the tool
        NSString* srcPath = [[NSBundle mainBundle] pathForResource: @"NetworkProxySetter" ofType: nil];
        assert(srcPath);
        [[self.xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            
        }] installNetworkToolAtSourcePath: srcPath withReply:^(BOOL success, NSString *message, NSError *error) {
            if (!success) {
                // TODO: show users some critical error message, liek try to re-install the application
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
        return;
    }
    
    
}

@end
