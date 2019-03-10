//
//  USBClientManager.m
//  CocoaApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Peertalk/Peertalk.h>
#import "USBClientManager.h"
#import "USBClient.h"
#import "RelayUSBClient.h"

@interface USBClientManager ()

@property (nonatomic, strong) NSMutableArray<RelayUSBClient*>* clients;

@end

@implementation USBClientManager

- (instancetype)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.clients = [[NSMutableArray alloc] init];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didAttachDevice:) name:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didDetachDevice:) name:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub];
}

- (void)didAttachDevice:(NSNotification*)notification {
    NSNumber* deviceId = notification.userInfo[@"DeviceID"];
    NSLog(@"attached %@", deviceId);
    
    USBClient* client = [[USBClient alloc] initWithDeviceId:deviceId];
    [client connect];
    RelayUSBClient* relayClient = [[RelayUSBClient alloc] initWithUSBClient:client];
    [self.clients addObject:relayClient];
}

- (void)didDetachDevice:(NSNotification*)notification {
    NSNumber* deviceId = notification.userInfo[@"DeviceID"];
    NSLog(@"detached %@", deviceId);
    
    NSMutableArray<RelayUSBClient*>* toRemove = [[NSMutableArray alloc] init];
    for (RelayUSBClient* client in self.clients) {
        if ([client.usbClient.deviceId isEqual:deviceId]) {
            [client.usbClient stop];;
            [toRemove addObject:client];
        }
    }
    
    [self.clients removeObjectsInArray:toRemove];
}

@end
