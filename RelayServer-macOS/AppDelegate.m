//
//  AppDelegate.m
//  RelayServer-macOS
//
//  Created by Igor Lira on 3/9/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "AppDelegate.h"
#import "USBClientManager.h"

#define ICON_OPACITY_ACTIVE 1
#define ICON_OPACITY_INACTIVE 0.3

@interface AppDelegate ()

@property (strong) USBClientManager* clientManager;
@property (strong) NSStatusItem* statusItem;
@property (strong) NSMenu* menu;
@property (strong) NSMenuItem* notConnectedMenuItem;
@property (strong) NSMenuItem* connectedMenuItem;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.clientManager = [[USBClientManager alloc] init];
    
    [self createStatusMenu];
    
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:20];
    self.statusItem.button.image = [NSImage imageNamed:@"menu_icon"];
    self.statusItem.button.alphaValue = 0.3;
    self.statusItem.menu = self.menu;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didConnectDevice:) name:nil object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didDisconnectDevice:) name:nil object:nil];
    
    [self refreshStatus];
}

- (void)createStatusMenu {
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Relay"];
    [menu addItemWithTitle:@"Relay" action:nil keyEquivalent:@""];
    [menu addItem:NSMenuItem.separatorItem];
    self.notConnectedMenuItem = [menu addItemWithTitle:@"Waiting for connections..." action:nil keyEquivalent:@""];
    self.connectedMenuItem = [menu addItemWithTitle:@"Connected to device!" action:nil keyEquivalent:@""];
    [menu addItem:NSMenuItem.separatorItem];
    [menu addItemWithTitle:@"Quit Relay" action:@selector(didPressQuit) keyEquivalent:@"Q"];
    
    self.menu = menu;
}

- (void)didPressQuit {
    [NSApplication.sharedApplication terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)didConnectDevice:(NSNotification*)notification {
    [self refreshStatus];
}

- (void)didDisconnectDevice:(NSNotification*)notification {
    [self refreshStatus];
}

- (void)refreshStatus {
    BOOL isConnected = self.clientManager.connectedClientCount > 0;
    
    self.statusItem.button.alphaValue = isConnected ? ICON_OPACITY_ACTIVE : ICON_OPACITY_INACTIVE;
    self.notConnectedMenuItem.hidden = isConnected;
    self.connectedMenuItem.hidden = !isConnected;
}

@end
