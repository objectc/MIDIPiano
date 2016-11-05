//
//  MidiAudioManager.m
//  TestMidi
//
//  Created by Tab on 21/10/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "MidiAudioManager.h"

@interface MidiAudioManager()
@property (readwrite) AUGraph processingGraph;
@property (readwrite) AUNode samplerNode;
@property (readwrite) AUNode ioNode;
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit ioUnit;
@property (readwrite) NoteInstanceID instanceID;
@end

@implementation MidiAudioManager


static MidiAudioManager *sharedManager = nil;

+ (MidiAudioManager *)sharedManager
{
    @synchronized(self){
        if (nil == sharedManager) {
            sharedManager = [[MidiAudioManager alloc] init];
        }
    }
    return sharedManager;
}

- (void)initSampleUnit{
    //    self.sampleUnit = audiounit
}


void MyMIDINotifyProc (const MIDINotification  *message, void *refCon) {
    printf("MIDI Notify, messageId=%d,", (int)message->messageID);
    
}

void MyMIDIReadProc (const MIDINotification  *message, void *refCon) {
    printf("MIDI Notify, messageId=%d,", (int)message->messageID);
    
}
- (instancetype)init{
    if(self = [super init]){
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph:self.processingGraph];
//    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Full Grand Piano" ofType:@"sf2"]];
    
    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Grand Piano" ofType:@"sf2"]];
        
    [self loadFromDLSOrSoundFont:soundFontFileURL withPatch:0];
    }
    return self;
}


- (MusicSequence)loadMidiFileWithURL:(NSURL*)url {
    
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph:self.processingGraph];

//    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Full Grand Piano" ofType:@"sf2"]];
//    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Electric Piano 4" ofType:@"SF2"]];
        NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Gorts_Filters" ofType:@"SF2"]];

    [self loadFromDLSOrSoundFont:soundFontFileURL withPatch:10];
    
    
    MusicSequence seq;
    NewMusicSequence(&seq);
    
    MusicSequenceFileLoad(seq, (__bridge CFURLRef)url, kMusicSequenceFile_AnyType, kMusicSequenceLoadSMF_ChannelsToTracks);
    MusicTrack tempoTrack;
    MusicSequenceGetTempoTrack(seq, &tempoTrack);
    
    MusicEventIterator iterator;
    NewMusicEventIterator(tempoTrack, &iterator);
    
    return seq; //remember to release seq by yourself
}

- (void)playMusicSequence:(MusicSequence)seq{
    MusicPlayer player;
    NewMusicPlayer(&player);
    MusicPlayerSetSequence(player, seq);
//    MusicPlayerPreroll(player);
    MusicPlayerStart(player);
    
    
    MusicTrack t;
    MusicTimeStamp len;
    UInt32 unitSize = sizeof(MusicTimeStamp);
    MusicSequenceGetIndTrack(seq, 1, &t);
    MusicTrackGetProperty(t, kSequenceTrackProperty_TrackLength, &len, &unitSize);
    
    
    while (1) { // 当播放结束时终止
        usleep (3 * 1000 * 1000);
        MusicTimeStamp now = 0;
        MusicPlayerGetTime (player, &now);
        if (now >= len)
            break;
    }
    
    
    
    MusicPlayerStop(player);
    DisposeMusicSequence(seq);
    DisposeMusicPlayer(player);
    
}

- (BOOL) createAUGraph {
    
    OSStatus result = noErr;
    
    AUNode samplerNode, ioNode;
    
    AudioComponentDescription cd = {};
    cd.componentManufacturer     = kAudioUnitManufacturer_Apple;
    
    result = NewAUGraph (&_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    cd.componentType = kAudioUnitType_MusicDevice;
    cd.componentSubType = kAudioUnitSubType_Sampler; //
    
    result = AUGraphAddNode (self.processingGraph, &cd, &samplerNode);
    NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    

    cd.componentType = kAudioUnitType_Output;  // Output
    cd.componentSubType = kAudioUnitSubType_RemoteIO;  // Output to speakers
    
    
    result = AUGraphAddNode (self.processingGraph, &cd, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Open
    result = AUGraphOpen (self.processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Connect the Sampler
    result = AUGraphConnectNodeInput (self.processingGraph, samplerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    result = AUGraphNodeInfo (self.processingGraph, samplerNode, 0, &_samplerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    result = AUGraphNodeInfo (self.processingGraph, ioNode, 0, &_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}


- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph {
    
    OSStatus result = noErr;
    if (graph) {
        
        
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        CAShow (graph);
    }
}

-(OSStatus) loadFromDLSOrSoundFont: (NSURL *)fileURL withPatch: (int)presetNumber {
    
    OSStatus result = noErr;
    

    AUSamplerInstrumentData instrumentData;
    instrumentData.fileURL  = (__bridge CFURLRef) fileURL;
    instrumentData.instrumentType = kInstrumentType_SF2Preset;
    instrumentData.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
    instrumentData.bankLSB  = kAUSampler_DefaultBankLSB;
    instrumentData.presetID = (UInt8) presetNumber;
    
//    AUSamplerBankPresetData bpdata;
//    bpdata.bankURL  = (__bridge CFURLRef) fileURL;
//    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
//    bpdata.bankLSB  = kAUSampler_DefaultBankLSB;
//    bpdata.presetID = (UInt8) presetNumber;
    
    
    result = AudioUnitSetProperty(self.samplerUnit,
                                  kAUSamplerProperty_LoadInstrument,
//                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &instrumentData,
                                  sizeof(instrumentData));
    
    NSCAssert (result == noErr,
               @"Unable to set the preset property on the Sampler. Error code:%d '%.4s'",
               (int) result,
               (const char *)&result);
    
    return result;
}

- (void)playNote:(UInt32)note{
    MusicDeviceMIDIEvent(self.samplerUnit, '\x90', note, 90, 3);
}

- (void)startPlayNote:(MusicDeviceNoteParams)note{
//    NoteInstanceID instanceID = 1;
    MusicDeviceStartNote(self.samplerUnit,kMusicNoteEvent_Unused,1,&_instanceID,1,&note);
}

- (void)stopPlayNote{
    MusicDeviceStopNote(self.samplerUnit, 1, self.instanceID, 1);
}


@end
