//
//  LYHAppDelegate.m
//  TcpServer
//
//  Created by Charles Leo on 14-10-8.
//  Copyright (c) 2014年 Charles Leo. All rights reserved.
//

#import "LYHAppDelegate.h"
#import "LYHTcpServer.h"
@implementation LYHAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // Insert code here to initialize your application
    LYHTcpServer * tcpServer = [[LYHTcpServer alloc]init];
    [tcpServer initialize];
}

@end
