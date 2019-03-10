//
//  USBRelayClient.h
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class USBRelayServer;
@class USBClient;
@class PTData;

@protocol USBRelayServerDelegate

- (void)usbClient:(USBClient*)usbClient didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData *)payload;
- (BOOL)usbClient:(USBClient*)usbClient shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize;
- (void)usbClientDidConnect:(USBClient*)client;
- (void)usbClientDidDisconnect;

@end

@interface USBRelayServer : NSObject

@property (nonatomic, weak) id<USBRelayServerDelegate> delegate;
@property (readonly) dispatch_queue_t serverQueue;

- (BOOL)isConnected;
- (void)sendFrameOfType:(uint32_t)type tag:(uint32_t)tag withPayload:(dispatch_data_t)data;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
