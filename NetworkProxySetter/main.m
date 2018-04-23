//
//  main.m
//  NetworkProxySetter
//
//  Created by 周向真 on 2018/4/10.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BRLOptionParser.h>
#import "ProxySetter.h"

#define VER_STRING  @"0.1"

#define ERR_OPTIONS -0x100

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Three modes: global / auto / off
        NSString* mode = @"off";
        NSString* pacUrl;
        NSString* port;
        NSMutableSet* byPass = [NSMutableSet new];
        NSMutableSet* networksServices = [NSMutableSet new];

        BRLOptionParser* optionParser = [BRLOptionParser new];
        ProxySetter* proxySetter = [ProxySetter sharedSetter];
        
        [optionParser setBanner: @"Usage: %s -[v] [-m auto|mode|off] [-u <url>] [-p <port>] [-x <exception>]", argv[0]];
        // Version option: -v
        [optionParser addOption: "version" flag: 'v' description: @"Print version number" block:^{
            printf("%s", [VER_STRING UTF8String]);
            exit(EXIT_SUCCESS);
        }];
        // Mode option: -m [auto | global | off]
        [optionParser addOption: "mode" flag: 'm' description: @"Proxy mode, could be: auto, global, off" argument: &mode];
        // Pac-url option: -u <url>
        [optionParser addOption: "pac-url" flag: 'u' description: @"PAC file url for auto mode" argument: &pacUrl];
        // Port option: -p <port>
        [optionParser addOption: "port" flag: 'p' description: @"Listen port for global mode" argument: &port];
        // Exception-list option: Call it like this: NetworkProxySetter -x a -x b -x c, then byPass list will be (a, b, c)
        [optionParser addOption: "proxy-exception" flag: 'x' description: @"By pass those Hosts / Domains" blockWithArgument:^(NSString *value) {
            [byPass addObject: value];
        }];
        // Manually set proxy: -n <set-key>
        [optionParser addOption: "proxy-services" flag: 'n' description: @"Mannually sepcify network profile whose proxy will be set" blockWithArgument:^(NSString *value) {
            [networksServices addObject: value];
        }];

        __weak typeof(optionParser) weakOptionParser = optionParser;
        [optionParser addOption: "help" flag: 'h' description: @"Show help banner of specified options" block:^{
            printf("%s", [[weakOptionParser description] UTF8String]);
            exit(EXIT_SUCCESS);
        }];

        NSError* error;
        if (![optionParser parseArgc: argc argv: argv error: &error]) {
            const char* errorMsg = error.localizedDescription.UTF8String;
            fprintf(stderr, "%s: %s", argv[0], errorMsg);
            exit(EXIT_FAILURE);
        }
        
        if (mode) {
            if ([mode isEqualToString: @"auto"]) {
                if (!pacUrl || [pacUrl isEqualToString: @""]) {
                    exit(ERR_OPTIONS);
                }
            } else if ([mode isEqualToString: @"global"]) {
                if (!port || [port integerValue] == 0) {
                    exit(ERR_OPTIONS);
                }
            } else if (![mode isEqualToString: @"off"]) {
                assert([mode isEqualToString: @"off"]);
                exit(ERR_OPTIONS);
            }
        }
        
        if ([mode isEqualToString:@"global"] && (!port || [port integerValue] == 0)) {
            exit(ERR_OPTIONS);
        }
        
//        [proxySetter saveProxies];
//        [proxySetter emptyProxies];
        if ([mode isEqualToString: @"auto"]) {
            [proxySetter emptyProxies];
            [proxySetter setPacEnabled: YES UrlString: pacUrl];
        } else if ([mode isEqualToString: @"global"]) {
            [proxySetter emptyProxies];
            [proxySetter setProxyForProtocol: @"Socks" Enabled: YES Url: @"127.0.0.1" Port: [port integerValue]];
        } else if ([mode isEqualToString: @"off"]) {
            // Let's think carefully how to retore proxy set before, for now, just empty it.
//            [proxySetter restoreProxies];
            [proxySetter emptyProxies];
        }
    }
    return 0;
}
