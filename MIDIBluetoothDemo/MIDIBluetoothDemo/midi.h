//
//  midi.h
//  Sibelius
//
//  Created by john goodstadt on 05/05/2011.
//  Copyright 2011 John Goodstadt. All rights reserved.
//  Use this file in your own projects as you see fit.
//  Please email me at john@goodstadt.me.uk for any problems, fixes, addition or thanks.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>


@interface Midi : NSObject {
    
    MIDIClientRef      client;
    MIDIPortRef        outputPort;
    MIDIPortRef        inputPort;
}

// avoid compile errors
-(void) sendBytes:(const UInt8*)bytes size:(UInt32)size;
-(void) sendPacketList:(const MIDIPacketList *)packetList;

@end

