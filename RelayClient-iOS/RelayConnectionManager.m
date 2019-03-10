//
//  RelayConnectionManager.m
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "RelayConnectionManager.h"
#import "USBRelayServer.h"
#import "SocketRelayServer.h"
#import "RelayProtocol.h"
#import "RelaySocket.h"
#import <Peertalk/Peertalk.h>

@interface RelayConnectionManager ()<USBRelayServerDelegate, SocketRelayServerDelegate>

@property (strong, nonatomic) dispatch_queue_t usbQueue;
@property (strong, nonatomic) USBRelayServer* usbServer;
@property (strong, nonatomic) NSMutableArray<SocketRelayServer*>* socketServers;

@end

@implementation RelayConnectionManager

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.usbQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    dispatch_suspend(self.usbQueue);
    
    self.usbServer = [[USBRelayServer alloc] init];
    self.usbServer.delegate = self;
    
    self.socketServers = [[NSMutableArray alloc] init];
}

- (void)addLocalPort:(NSNumber*)port relayPort:(NSNumber*)relayPort {
    SocketRelayServer* socketServer = [[SocketRelayServer alloc] initWithLocalPort:port relayPort:relayPort];
    socketServer.delegate = self;
    
    [self.socketServers addObject:socketServer];
}

- (void)start {
    [self.usbServer start];
    for (SocketRelayServer* socketServer in self.socketServers) {
        [socketServer start];
    }
}

- (void)stop {
    [self.usbServer stop];
    for (SocketRelayServer* socketServer in self.socketServers) {
        [socketServer stop];
    }
}

- (void)socketRelayServer:(SocketRelayServer *)server didAcceptConnection:(RelaySocket *)connection {
    if (self.usbServer.isConnected || self.hangIfNotConnected) {
        dispatch_async(self.usbQueue, ^{
            PTRelayConnectFrame* frame = CFAllocatorAllocate(nil, sizeof(PTRelayConnectFrame), 0);
            frame->handle = connection.handle.unsignedShortValue;
            frame->port = 8081;
            dispatch_data_t dispatchData = dispatch_data_create(frame, sizeof(PTRelayConnectFrame), self.usbServer.serverQueue, ^{
                CFAllocatorDeallocate(nil, frame);
            });
            
            [self.usbServer sendFrameOfType:PTRelayFrameTypeConnect tag:0 withPayload:dispatchData];
        });
    } else {
        [connection close];
    }
}

- (void)socketRelayServer:(SocketRelayServer *)server didCloseConnection:(RelaySocket *)connection {
    if (self.usbServer.isConnected || self.hangIfNotConnected) {
        dispatch_async(self.usbQueue, ^{
            PTRelayDisconnectFrame* frame = CFAllocatorAllocate(nil, sizeof(PTRelayDisconnectFrame), 0);
            frame->handle = connection.handle.unsignedShortValue;
            dispatch_data_t dispatchData = dispatch_data_create(frame, sizeof(PTRelayDisconnectFrame), self.usbServer.serverQueue, ^{
                CFAllocatorDeallocate(nil, frame);
            });
            
            [self.usbServer sendFrameOfType:PTRelayFrameTypeDisconnect tag:0 withPayload:dispatchData];
        });
    }
}

- (void)relaySocket:(RelaySocket *)socket didReceiveData:(NSData *)data {
    if (self.usbServer.isConnected || self.hangIfNotConnected) {
        dispatch_async(self.usbQueue, ^{
            PTRelayWriteFrame* frame = CFAllocatorAllocate(nil, sizeof(PTRelayWriteFrame) + data.length, 0);
            frame->handle = socket.handle.unsignedShortValue;
            frame->length = data.length;
            [data getBytes:&frame->data length:data.length];
            
            dispatch_data_t dispatchData = dispatch_data_create(frame, sizeof(PTRelayWriteFrame) + data.length, self.usbServer.serverQueue, ^{
                CFAllocatorDeallocate(nil, frame);
            });
            [self.usbServer sendFrameOfType:PTRelayFrameTypeWrite tag:0 withPayload:dispatchData];
        });
    } else {
        [socket close];
    }
}

- (BOOL)usbClient:(USBClient *)usbClient shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return type == PTRelayFrameTypeWrite || type == PTRelayFrameTypeDisconnect;
}

- (void)usbClient:(USBClient *)usbClient didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload {
    NSLog(@"[USB] Received frame of type %u", type);
    if (type == PTRelayFrameTypeWrite) {
        PTRelayWriteFrame* frame = payload.data;
        NSData* data = [[NSData alloc] initWithBytes:frame->data length:frame->length];
        
        RelaySocket* connection = [self connectionWithHandle:@(frame->handle)];
        if (connection) {
            [connection sendData:data];
        } else {
            NSLog(@"[USB] Could not find connection for handle %@", @(frame->handle));
        }
        
        NSLog(@"[USB] write %u bytes to socket %u", frame->length, frame->handle);
    } else if (type == PTRelayFrameTypeDisconnect) {
        PTRelayDisconnectFrame* frame = payload.data;
        
        RelaySocket* connection = [self connectionWithHandle:@(frame->handle)];
        [connection close];
        
        NSLog(@"[USB] disconnect:%u", frame->handle);
    }
}

- (RelaySocket*)connectionWithHandle:(NSNumber*)handle {
    for (SocketRelayServer* socketServer in self.socketServers) {
        RelaySocket* connection = [socketServer connectionWithHandle:handle];
        if (connection) {
            return connection;
        }
    }
    return nil;
}

- (void)usbClientDidConnect:(USBClient *)client {
    dispatch_resume(self.usbQueue);
}

- (void)usbClientDidDisconnect {
    dispatch_suspend(self.usbQueue);
}

@end
