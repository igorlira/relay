//
//  RelayConnectionManager.h
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RelayConnectionManager : NSObject

@property BOOL hangIfNotConnected;

- (void)start;
- (void)stop;
- (void)addLocalPort:(NSNumber*)port relayPort:(NSNumber*)relayPort;

@end

NS_ASSUME_NONNULL_END
