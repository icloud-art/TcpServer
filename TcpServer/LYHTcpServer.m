//
//  LYHTcpServer.m
//  TcpServer
//
//  Created by Charles Leo on 14-10-8.
//  Copyright (c) 2014年 Charles Leo. All rights reserved.
//

#import "LYHTcpServer.h"
#import <sys/socket.h>
#import <arpa/inet.h>
@implementation LYHTcpServer

void readStream(CFReadStreamRef isStream,CFStreamEventType eventType,void * clientCallBackInfo){
    UInt8 buff[2048];
    CFIndex hasRead = CFReadStreamRead(isStream, buff, 2048);
    if (hasRead > 0) {
        buff[hasRead] = '\0';
        printf("接收到数据: %s \n",buff);
    }
}

void TCPServerAcceptCallBack(CFSocketRef socket,CFSocketCallBackType type,CFDataRef address,const void * data,void * info)
{
    //如果有客户端socket连接进来
    if (kCFSocketAcceptCallBack == type) {
        //获取本地socket的handle
        CFSocketNativeHandle  nativeSocketHandle = *(CFSocketNativeHandle *)data;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t nameLen = sizeof(name);
        if (getpeername(nativeSocketHandle, (struct sockaddr *) name, &nameLen) != 0) {
            NSLog(@"error!");
            exit(1);
        }
        //获取连接信息
        struct sockaddr_in * addr_in = (struct sockaddr_in *)name;
        NSLog(@"%s:%d连接进来了!",inet_ntoa(addr_in ->sin_addr),addr_in ->sin_port);
        CFReadStreamRef iStream;
        CFWriteStreamRef oStream;
        
        //创建一组可读/写的CFStream
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
        if (iStream && oStream) {
            CFReadStreamOpen(iStream);
            CFWriteStreamOpen(oStream);
            CFStreamClientContext streamContext = {0,NULL,NULL,NULL};
            if (!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable, readStream, &streamContext)) {
                exit(1);
            }
            CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            const char * str = "您好,连接到了Mac服务器!\n";
            CFWriteStreamWrite(oStream, (UInt8 *)str, strlen(str) + 1);
        }
    }
}

-(void)initialize{
    //创建socket
    CFSocketRef _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack,TCPServerAcceptCallBack , NULL);
    if (_socket == NULL) {
        NSLog(@"创建失败!");
    }
    int optval = 1;
    //设置允许重用本地地址和端口
    setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&optval, sizeof(optval));
    //定义sockaddr_in类型变量,该变量将作为CFSocket的地址
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    //设置该服务器监听本机任意可用的IP地址
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    //设置服务监听地址
    addr4.sin_addr.s_addr = inet_addr("192.168.5.22");
    //设置服务器监听端口
    addr4.sin_port = htons(30000);
    //将IPv4的地址转换为CFDataRef
    CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
    //将CFSocket绑定到指定IP地址
    if (CFSocketSetAddress(_socket, address) != kCFSocketSuccess) {
        NSLog(@"地址绑定失败!");
        //如果_socket不为NULL,则释放_socket
        if (_socket) {
            CFRelease(_socket);
            exit(1);
        }
        _socket = NULL;
    }
    NSLog(@"---启动循环监听客户端连接---");
    //获取当前线程的CFRunLoop
    
    CFRunLoopRef cfRunLoop = CFRunLoopGetCurrent();
    //将_socket包装成 CFRunLoopSource
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    //为CFRunLoop对象添加source
    CFRunLoopAddSource(cfRunLoop, source, kCFRunLoopCommonModes);
    CFRelease(source);
    CFRunLoopRun();
}







@end
