#ifndef RelayProtocol_h
#define RelayProtocol_h

#import <Foundation/Foundation.h>
#include <stdint.h>

static const int PTRelayIPv4PortNumber = 2345;

enum {
    PTRelayFrameTypeConnect = 100,
    PTRelayFrameTypeWrite = 101,
    PTRelayFrameTypeDisconnect = 103
};

typedef struct {
    uint16_t handle;
    uint16_t port;
} PTRelayConnectFrame;

typedef struct {
    uint16_t handle;
    uint32_t length;
    uint8_t data[0];
} PTRelayWriteFrame;

typedef struct {
    uint16_t handle;
} PTRelayDisconnectFrame;

#endif
