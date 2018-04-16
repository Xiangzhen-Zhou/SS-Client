//
//  main.m
//  NetworkProxySetter
//
//  Created by 周向真 on 2018/4/10.
//  Copyright © 2018年 zxzerster. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ProxySetter.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        ProxySetter* proxySetter = [ProxySetter sharedSetter];
        [proxySetter setProxyForProtocol: @"Http" Enabled: YES Url: @"http://test.com" Port: 1234];
        [proxySetter setProxyForProtocol: @"Https" Enabled: YES Url: @"https://test.com" Port: 5678];
        [proxySetter setProxyForProtocol: @"Socks" Enabled: YES Url: @"http://socks.com" Port:1357];
        [proxySetter setExceptionList: @[@"http://1.com", @"http://2.com", @"http://3.com"]];
        [proxySetter setPacEnabled: YES UrlString: @"http://pacUrl.com"];
        [proxySetter setProxyForProtocol: @"Http" Enabled: YES Url: @"http://test.com" Port: 1234];
        NSLog(@"Set proxy finished...");
    }
    return 0;
}
