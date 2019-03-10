//
//  RelayUSBClient.h
//  CocoaApp
//
//  Created by Igor Lira on 3/7/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class USBClient;

@interface RelayUSBClient : NSObject

@property (readonly) USBClient* usbClient;
- (instancetype)initWithUSBClient:(USBClient*)usbClient;

@end

NS_ASSUME_NONNULL_END
