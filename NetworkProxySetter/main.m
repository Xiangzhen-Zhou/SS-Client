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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Three modes: global / auto / off
        NSString* mode = @"off";
        NSString* pacUrl;
        NSString* port;

        BRLOptionParser* optionParser = [BRLOptionParser new];

        [optionParser setBanner: @"Usage: %s -[v] [-m auto|mode|off] [-u <url>] [-p <port>] [-x <exception>]", argv[0]];
        [optionParser addOption: "mode" flag: 'm' description: @"Proxy mode, could be: auto, global, off" argument: &mode];
        [optionParser addOption: "url" flag: 'u' description: @"PAC file url for auto mode" argument: &pacUrl];
        [optionParser addOption: "port" flag: 'p' description: @"Listen port for global mode" argument: &port];

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
        
//        ProxySetter* proxySetter = [ProxySetter sharedSetter];
//        [proxySetter setProxyForProtocol: @"Http" Enabled: YES Url: @"http://test.com" Port: 1234];
//        [proxySetter setProxyForProtocol: @"Https" Enabled: YES Url: @"https://test.com" Port: 5678];
//        [proxySetter setProxyForProtocol: @"Socks" Enabled: YES Url: @"http://socks.com" Port:1357];
//        [proxySetter setExceptionList: @[@"http://1.com", @"http://2.com", @"http://3.com"]];
//        [proxySetter setPacEnabled: YES UrlString: @"http://pacUrl.com"];
//        [proxySetter setProxyForProtocol: @"Http" Enabled: YES Url: @"http://test.com" Port: 1234];
//        NSLog(@"Set proxy finished...");
    }
    return 0;
}
