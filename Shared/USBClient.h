//
//  USBClient.h
//  MacApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class USBClient;
@class PTData;
@class PTChannel;

@protocol USBClientDelegate

- (void)usbClient:(USBClient*)usbClient didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload;
- (BOOL)usbClient:(USBClient*)usbClient shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize;
- (void)usbClient:(USBClient*)usbClient didEndWithError:(NSError*)error;
- (void)usbClientDidConnect:(USBClient*)usbClient;

@end

@interface USBClient : NSObject

@property (nonatomic, weak) id<USBClientDelegate> delegate;

- (instancetype)initWithDeviceId:(NSNumber*)deviceId;
- (instancetype)initWithChannel:(PTChannel*)channel;
- (NSNumber*)deviceId;
- (void)connect;
- (void)stop;
- (BOOL)isConnected;
- (void)sendFrameOfType:(uint32_t)type tag:(uint32_t)tag withPayload:(dispatch_data_t)payload;

@end

NS_ASSUME_NONNULL_END
