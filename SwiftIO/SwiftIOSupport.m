//
//  SwiftIOSupport.m
//  SwiftIO
//
//  Created by Jonathan Wight on 9/28/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ifaddrs.h>
#import <arpa/inet.h>

// TODO: INET vs INET6
NSDictionary *getAddressesForInterfaces() {

    NSMutableDictionary *addressesForInterfaces = [NSMutableDictionary dictionary];

    struct ifaddrs *interfaces = NULL;
    int success = getifaddrs(&interfaces);
    if (success != 0) {
        return nil;
    }

    // Loop through linked list of interfaces
    struct ifaddrs *current = interfaces;
    while (current != NULL) {
        if (current->ifa_addr->sa_family == AF_INET) {
            NSString *interfaceName = [NSString stringWithUTF8String:current->ifa_name];

            NSData *addressData = [NSData dataWithBytes:current->ifa_addr length:current->ifa_addr->sa_len];

            addressesForInterfaces[interfaceName] = addressData;
        }
        current = current->ifa_next;
    }

    freeifaddrs(interfaces);
    return addressesForInterfaces;
}