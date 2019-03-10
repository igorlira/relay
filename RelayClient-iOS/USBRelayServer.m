//
//  USBRelayClient.m
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "USBRelayServer.h"
#import <Peertalk/Peertalk.h>
#import "USBClient.h"

@interface USBRelayServer ()<PTChannelDelegate, USBClientDelegate>

@property (nonatomic, strong) dispatch_queue_t serverQueue;
@property (nonatomic, strong) PTChannel* serverChannel;
@property (nonatomic, strong) USBClient* currentChannel;

@end

@implementation USBRelayServer

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.serverQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    self.serverChannel = [[PTChannel alloc] initWithProtocol:[PTProtocol sharedProtocolForQueue:self.serverQueue] delegate:self];
}

- (void)start {
    [self.serverChannel listenOnPort:1337 IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
        if (error) {
            NSLog(@"Could not listen: %@", error.localizedDescription);
        } else {
            NSLog(@"Listening...");
        }
    }];
}

- (void)stop {
    [self.serverChannel close];
    [self closeCurrentChannel];
    [self.delegate usbClientDidDisconnect];
}

- (void)closeCurrentChannel {
    if (self.currentChannel) {
        self.currentChannel.delegate = nil;
        [self.currentChannel stop];
        self.currentChannel = nil;
    }
}

- (BOOL)isConnected {
    return self.currentChannel && self.currentChannel.isConnected;
}

- (void)ioFrameChannel:(PTChannel *)channel didAcceptConnection:(PTChannel *)otherChannel fromAddress:(PTAddress *)address {
    NSLog(@"Accepted connection");
    
    [self closeCurrentChannel];
    
    self.currentChannel = [[USBClient alloc] initWithChannel:otherChannel];
    self.currentChannel.delegate = self;
    
    [self.delegate usbClientDidConnect:self.currentChannel];
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error {
    if (error) {
        NSLog(@"Ended with error: %@", error);
    } else {
        NSLog(@"Ended");
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload {
    NSLog(@"this should not happen received");
}

- (void)sendFrameOfType:(uint32_t)type tag:(uint32_t)tag withPayload:(dispatch_data_t)data {
    [self.currentChannel sendFrameOfType:type tag:tag withPayload:data];
}

- (void)usbClient:(USBClient *)usbClient didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload {
    [self.delegate usbClient:usbClient didReceiveFrameOfType:type tag:tag payload:payload];
}

- (BOOL)usbClient:(USBClient *)usbClient shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return [self.delegate usbClient:usbClient shouldAcceptFrameOfType:type tag:tag payloadSize:payloadSize];
}

- (void)usbClient:(USBClient *)usbClient didEndWithError:(NSError *)error {
    if (usbClient == self.currentChannel) {
        [self closeCurrentChannel];
        [self.delegate usbClientDidDisconnect];
    }
    
    if (error) {
        NSLog(@"Ended with error: %@", error);
    } else {
        NSLog(@"Ended");
    }
}

@end
