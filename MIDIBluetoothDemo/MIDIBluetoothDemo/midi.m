//
//  midi.m
//
//  Created by john goodstadt on 05/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//  Use this file in your own projects as you see fit.
//  Please email me at john@goodstadt.me.uk for any problems, fixes, addition or thanks.
//

#import "midi.h"

/// A helper that NSLogs an error message if "c" is an error code
#define NSLogError(c,str) do{if (c) NSLog(@"Error (%@): %lu:%@", str, c,[NSError errorWithDomain:NSMachErrorDomain code:c userInfo:nil]);}while(false)




@implementation Midi


- (id) init
{
    if ((self = [super init]))
    {       

        
        
        OSStatus s = MIDIClientCreate((CFStringRef)@"MidiMonitor MIDI Client", nil, (__bridge void *)(self), &client);
        NSLog(@"Create MIDI client");
        
        s = MIDIOutputPortCreate(client, (CFStringRef)@"MidiMonitor Output Port", &outputPort);
    }
    

    return self;
}


#pragma mark Send Routines
//发送字节数据
- (void) sendBytes:(const UInt8*)bytes size:(UInt32)size
{
    //数据结构转换
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, bytes);
 
    
    [self sendPacketList:packetList];
}


- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if (outputEndpoint)
        {
            // Send it
            OSStatus s = MIDISend(outputPort, outputEndpoint, packetList);
            NSLogError(s, @"Sending MIDI");
        }
    }
}






@end
