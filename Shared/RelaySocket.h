//
//  RelayConnection.h
//  CocoaApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RelaySocket;
@class GCDAsyncSocket;

@protocol RelaySocketDelegate

- (void)relaySocket:(RelaySocket*)socket didReceiveData:(NSData*)data;
- (void)relaySocketDidDisconnect:(RelaySocket*)socket;

@end

@interface RelaySocket : NSObject

@property (nonatomic, weak) id<RelaySocketDelegate> delegate;
@property (readonly) NSNumber* handle;

- (instancetype)initWithHandle:(NSNumber*)handle destPort:(NSNumber*)port;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket delegate:(id<RelaySocketDelegate>)delegate handle:(NSNumber*)handle;
- (void)connect;
- (void)sendData:(NSData*)data;
- (void)close;

@end

NS_ASSUME_NONNULL_END
