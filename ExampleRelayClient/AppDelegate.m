//
//  AppDelegate.m
//  ExampleRelayClient
//
//  Created by Igor Lira on 3/9/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "AppDelegate.h"
#import "RelayConnectionManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) RelayConnectionManager* relayManager;

@end

@implementation AppDelegate

- (BOOL)isPackagerRunning
{
    NSURL *url = [NSURL URLWithString:@"http://localhost:8081/status"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse *response;
    NSError* error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [status isEqualToString:@"packager-status:running"];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.relayManager = [[RelayConnectionManager alloc] init];
    self.relayManager.hangIfNotConnected = YES;
    [self.relayManager addLocalPort:@(8081) relayPort:@(8081)];
    [self.relayManager start];
    
    NSLog(@"asd %@", @([self isPackagerRunning]));
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.relayManager stop];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [self.relayManager start];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
