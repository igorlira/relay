//
//  USBClient.m
//  MacApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "USBClient.h"
#import <Peertalk/Peertalk.h>

@interface USBClient ()<PTChannelDelegate>

@property (nonatomic, copy) NSNumber* deviceId;
@property (nonatomic) dispatch_queue_t notConnectedQueue;
@property (nonatomic) dispatch_queue_t writeQueue;
@property (nonatomic, strong) PTChannel* channel;
@property (nonatomic, assign) BOOL isConnected;

@property (nonatomic, assign) BOOL isRunning;

@end

@implementation USBClient

- (instancetype)initWithDeviceId:(NSNumber *)deviceId {
    if (self = [super init]) {
        self.deviceId = deviceId;
        [self initialize];
    }
    return self;
}

- (instancetype)initWithChannel:(PTChannel*)channel {
    if (self = [super init]) {
        self.channel = channel;
        self.isRunning = YES;
        self.isConnected = channel.isConnected;
        self.channel.delegate = self;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.notConnectedQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    self.writeQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    
    if (self.channel.isConnected) {
        self.isConnected = YES;
        dispatch_suspend(self.notConnectedQueue);
    }
}

- (void)connect {
    self.isRunning = YES;
    
    self.channel = [PTChannel channelWithDelegate:self];
    [self dispatchConnect];
}

- (void)stop {
    self.isRunning = NO;
    [self close];
}

- (void)dispatchConnect {
    dispatch_async(self.notConnectedQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.channel connectToPort:1337 overUSBHub:PTUSBHub.sharedHub deviceID:self.deviceId callback:^(NSError *error) {
                if (error && self.isRunning) {
                    [self performSelector:@selector(dispatchConnect) withObject:nil afterDelay:1];
                } else if (self.isRunning) {
                    [self didConnect];
                }
            }];
        });
    });
}

- (void)sendFrameOfType:(uint32_t)type tag:(uint32_t)tag withPayload:(dispatch_data_t)payload {
    dispatch_async(self.writeQueue, ^{
        dispatch_suspend(self.writeQueue);
        //dispatch_sync(dispatch_get_main_queue(), ^{
            [self.channel sendFrameOfType:type tag:tag withPayload:payload callback:^(NSError *error) {
                dispatch_resume(self.writeQueue);
                if (error) {
                    [self didDisconnect];
                }
            }];
        //});
    });
}

- (void)close {
    if (self.channel) {
        [self.channel close];
        self.channel = nil;
    }
}

- (void)didConnect {
    NSLog(@"connected to %@", self.deviceId);
    
    dispatch_suspend(self.notConnectedQueue);
    self.isConnected = YES;
    
    [self.delegate usbClientDidConnect:self];
}

- (void)didDisconnect {
    if (self.isConnected) {
        NSLog(@"disconnected from %@", self.deviceId);
        
        dispatch_resume(self.notConnectedQueue);
        self.isConnected = NO;
        
        if (self.isRunning && self.deviceId) {
            [self performSelector:@selector(dispatchConnect) withObject:nil afterDelay:1];
        }
    }
}

- (void)ioFrameChannel:(PTChannel *)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload {
    [self.delegate usbClient:self didReceiveFrameOfType:type tag:tag payload:payload];
}

- (BOOL)ioFrameChannel:(PTChannel *)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    return [self.delegate usbClient:self shouldAcceptFrameOfType:type tag:tag payloadSize:payloadSize];
}

- (void)ioFrameChannel:(PTChannel *)channel didEndWithError:(NSError *)error {
    if (self.isConnected) {
        [self didDisconnect];
        NSLog(@"ended %@", error);
        
        [self.delegate usbClient:self didEndWithError:error];
    }
}

@end
