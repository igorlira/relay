//
//  SocketRelayClient.m
//  PeerTalkTest
//
//  Created by Igor Lira on 3/5/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "SocketRelayServer.h"
#import "GCDAsyncSocket.h"
#import "RelaySocket.h"

@interface SocketRelayServer ()<GCDAsyncSocketDelegate, RelaySocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket* serverSocket;
@property (nonatomic, strong) NSMutableArray<RelaySocket*>* connections;
@property (nonatomic, strong) dispatch_queue_t socketQueue;
@property (nonatomic, copy) NSNumber* localPort;
@property (nonatomic, copy) NSNumber* relayPort;

@end

@implementation SocketRelayServer

- (instancetype)initWithLocalPort:(NSNumber*)localPort relayPort:(NSNumber*)relayPort {
    if (self = [super init]) {
        self.localPort = localPort;
        self.relayPort = relayPort;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.connections = [[NSMutableArray alloc] init];
    self.socketQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketQueue];
}

- (void)start {
    NSError* error = nil;
    if (![self.serverSocket acceptOnPort:self.localPort.unsignedShortValue error:&error]) {
        NSLog(@"Could not start socket: %@", error);
        return;
    }
    
    NSLog(@"[Socket] Listening...");
}

- (void)stop {
    [self.serverSocket disconnect];
    for (RelaySocket* connection in self.connections) {
        [connection close];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    RelaySocket* client = [[RelaySocket alloc] initWithSocket:newSocket delegate:self handle:@(newSocket.connectedPort)];
    [self.connections addObject:client];
    
    NSLog(@"[Socket] Accepted socket #%@", client.handle);
    [self.delegate socketRelayServer:self didAcceptConnection:client];
}

- (void)relaySocket:(RelaySocket *)socket didReceiveData:(NSData *)data {
    [self.delegate relaySocket:socket didReceiveData:data];
}

- (void)relaySocketDidDisconnect:(RelaySocket *)socket {
    NSLog(@"[Socket] #%@ disconnected", socket.handle);
    [self.delegate socketRelayServer:self didCloseConnection:socket];
    
    [self.connections removeObject:socket];
}

- (RelaySocket*)connectionWithHandle:(NSNumber*)handle {
    for (RelaySocket* socket in self.connections) {
        if ([socket.handle isEqualToNumber:handle]) {
            return socket;
        }
    }
    return nil;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

@end
