//
//  AppDelegate.m
//  RelayServer-macOS
//
//  Created by Igor Lira on 3/9/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "AppDelegate.h"
#import "USBClientManager.h"

@interface AppDelegate ()

@property (strong) USBClientManager* clientManager;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.clientManager = [[USBClientManager alloc] init];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
