//
//  MidiAudioManager.h
//  TestMidi
//
//  Created by Tab on 21/10/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface MidiAudioManager : NSObject

+(id)sharedManager;
- (MusicSequence)loadMidiFileWithURL:(NSURL*)url;
- (void)playMusicSequence:(MusicSequence)seq;
- (void)playNote:(UInt32)note;

- (void)startPlayNote:(MusicDeviceNoteParams)note;
- (void)stopPlayNote;
-(OSStatus) loadFromDLSOrSoundFont: (NSURL *)fileURL withPatch: (int)presetNumber;
@end
