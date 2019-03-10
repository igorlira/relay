//
//  RelayConnection.m
//  CocoaApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "RelaySocket.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface RelaySocket ()<GCDAsyncSocketDelegate>

@property (nonatomic, copy) NSNumber* handle;
@property (nonatomic, copy) NSNumber* destPort;

@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, strong) dispatch_queue_t readQueue;
@property (nonatomic, strong) dispatch_queue_t writeQueue;
@property (nonatomic, strong) GCDAsyncSocket* socket;
@property BOOL isConnected;

@end

@implementation RelaySocket

/**
 * This socket connects to the desired port and relay its communication to a delegate
 */

- (instancetype)initWithHandle:(NSNumber*)handle destPort:(NSNumber*)port {
    if (self = [super init]) {
        self.handle = handle;
        self.destPort = port;
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self initialize];
    }
    return self;
}

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket delegate:(id<RelaySocketDelegate>)delegate handle:(NSNumber*)handle {
    if (self = [super init]) {
        self.handle = handle;
        self.socket = socket;
        self.delegate = delegate;
        self.socket.delegate = self;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.socketQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    self.readQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    self.writeQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    
    if (self.socket && self.socket.isConnected) {
        self.isConnected = YES;
        [self dispatchRead];
    }
}

- (void)connect {
    NSError* error = nil;
    [self.socket connectToHost:@"localhost" onPort:self.destPort.shortValue error:&error];
    if (error) {
        NSLog(@"[Socket #%@] Could not connect to localhost:%@: %@", self.handle, self.destPort, error);
    } else {
        NSLog(@"[Socket #%@] Connecting to localhost:%@...", self.handle, self.destPort);
    }
}

- (void)close {
    self.isConnected = NO;
    [self.socket disconnect];
    self.socket = nil;
}

- (void)dispatchRead {
    /*dispatch_async(self.readQueue, ^{
        //dispatch_suspend(self.readQueue);
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_suspend(self.readQueue);
            //[self.socket readDataWithTimeout:30 tag:0];
        });
    });*/
    [self.socket readDataWithTimeout:30 tag:0];
}

- (void)sendData:(NSData*)data {
    dispatch_async(self.writeQueue, ^{
        // dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_suspend(self.writeQueue);
            [self.socket writeData:data withTimeout:30 tag:0];
        // });
    });
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.isConnected = YES;
    NSLog(@"[Socket #%@] Connected to %@:%i", self.handle, host, port);
    
    [self dispatchRead];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (self.isConnected) {
        [self.delegate relaySocket:self didReceiveData:data];
        //dispatch_resume(self.readQueue);
        [self dispatchRead];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (self.isConnected) {
        dispatch_resume(self.writeQueue);
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.delegate relaySocketDidDisconnect:self];
}

@end
