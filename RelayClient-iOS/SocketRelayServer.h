//
//  SocketRelayClient.h
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RelaySocket;
@class SocketRelayServer;

@protocol SocketRelayServerDelegate

- (void)socketRelayServer:(SocketRelayServer*)server didAcceptConnection:(RelaySocket*)connection;
- (void)socketRelayServer:(SocketRelayServer*)server didCloseConnection:(RelaySocket*)connection;
- (void)relaySocket:(RelaySocket*)socket didReceiveData:(NSData*)data;

@end

@interface SocketRelayServer : NSObject

@property (nonatomic, weak) id<SocketRelayServerDelegate> delegate;
@property (readonly) NSNumber* localPort;
@property (readonly) NSNumber* relayPort;

- (instancetype)initWithLocalPort:(NSNumber*)localPort relayPort:(NSNumber*)relayPort;
- (RelaySocket*)connectionWithHandle:(NSNumber*)handle;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
