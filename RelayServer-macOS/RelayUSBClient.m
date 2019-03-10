//
//  RelayUSBClient.m
//  CocoaApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "RelayUSBClient.h"
#import "USBClient.h"
#import "RelaySocket.h"
#import "RelayProtocol.h"
#import <Peertalk/Peertalk.h>

@interface RelayUSBClient ()<USBClientDelegate, RelaySocketDelegate>

@property (nonatomic, strong) NSMutableArray<RelaySocket*>* connections;
@property (nonatomic, strong) USBClient* usbClient;
@property (nonatomic, strong) dispatch_queue_t usbQueue;

@end

@implementation RelayUSBClient

- (instancetype)initWithUSBClient:(USBClient*)usbClient {
    if (self = [super init]) {
        self.usbClient = usbClient;
        self.usbClient.delegate = self;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.usbQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    dispatch_suspend(self.usbQueue);
    
    self.connections = [[NSMutableArray alloc] init];
}

#pragma mark - Connection management

- (void)connectToPort:(NSNumber*)port usingHandle:(NSNumber*)handle {
    RelaySocket* socket = [[RelaySocket alloc] initWithHandle:handle destPort:port];
    [self.connections addObject:socket];
    
    socket.delegate = self;
    [socket connect];
}

- (BOOL)usbClient:(USBClient *)usbClient shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return type == PTRelayFrameTypeConnect || type == PTRelayFrameTypeWrite || type == PTRelayFrameTypeDisconnect;
}

- (void)usbClient:(USBClient *)usbClient didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload {
    NSLog(@"[USB] Received frame of type %u", type);
    if (type == PTRelayFrameTypeConnect) {
        PTRelayConnectFrame* frame = payload.data;
        [self connectToPort:@(frame->port) usingHandle:@(frame->handle)];
    } else if (type == PTRelayFrameTypeWrite) {
        PTRelayWriteFrame* frame = payload.data;
        NSData* data = [NSData dataWithBytes:frame->data length:frame->length];
        
        RelaySocket* connection = [self connectionWithHandle:@(frame->handle)];
        [connection sendData:data];
    } else if (type == PTRelayFrameTypeDisconnect) {
        PTRelayDisconnectFrame* frame = payload.data;
        RelaySocket* connection = [self connectionWithHandle:@(frame->handle)];
        [connection close];
    }
}

- (void)usbClientDidConnect:(USBClient*)client {
    NSLog(@"[USB] Connected");
    dispatch_resume(self.usbQueue);
}

- (void)usbClient:(USBClient *)usbClient didEndWithError:(NSError *)error {
    NSLog(@"[USB] Disconnected");
    dispatch_suspend(self.usbQueue);
}

- (RelaySocket*)connectionWithHandle:(NSNumber*)handle {
    for (RelaySocket* socket in self.connections) {
        if ([socket.handle isEqualToNumber:handle]) {
            return socket;
        }
    }
    return nil;
}

- (void)relaySocket:(RelaySocket *)socket didReceiveData:(NSData *)data {
    NSLog(@"[Socket #%@] Received %lu bytes from socket", socket.handle, data.length);
    
    dispatch_async(self.usbQueue, ^{
        PTRelayWriteFrame* frame = CFAllocatorAllocate(nil, sizeof(PTRelayWriteFrame) + data.length, 0);
        frame->handle = socket.handle.unsignedIntValue;
        frame->length = data.length;
        
        [data getBytes:&frame->data length:data.length];
        
        dispatch_data_t dispatchData = dispatch_data_create(frame, sizeof(PTRelayWriteFrame) + data.length, nil, ^{
            CFAllocatorDeallocate(nil, frame);
        });
        [self.usbClient sendFrameOfType:PTRelayFrameTypeWrite tag:0 withPayload:dispatchData];
        NSLog(@"[USB] write %lu bytes to handle %@", data.length, socket.handle);
    });
}

- (void)relaySocketDidDisconnect:(RelaySocket *)socket {
    NSLog(@"Socket #%@ disconnected", socket.handle);
    [self.connections removeObject:socket];
    
    dispatch_async(self.usbQueue, ^{
        PTRelayDisconnectFrame* frame = CFAllocatorAllocate(nil, sizeof(PTRelayDisconnectFrame), 0);
        frame->handle = socket.handle.unsignedShortValue;
        
        dispatch_data_t dispatchData = dispatch_data_create(frame, sizeof(PTRelayDisconnectFrame), nil, ^{
            CFAllocatorDeallocate(nil, frame);
        });
        [self.usbClient sendFrameOfType:PTRelayFrameTypeDisconnect tag:0 withPayload:dispatchData];
    });
}

@end
