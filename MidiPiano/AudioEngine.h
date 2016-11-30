//
//  AudioEngine.h
//  MidiPiano
//
//  Created by Tab on 10/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

@class AudioEngine;
@protocol ToneGeneratorDelegate <NSObject>
- (float) requestForToneFrequency;

@end

@protocol FFTDelegate <NSObject>

- (void) returnMaxFrequency:(float)maxFrequency;

@end

@interface AudioEngine : NSObject

@property (nonatomic,weak) id<ToneGeneratorDelegate,FFTDelegate>delegate;
@property (nonatomic,strong) AVAudioUnitSampler *instrumentsNode;
@property (nonatomic,assign) BOOL isMIDIPlaying;
@property (nonatomic,assign) BOOL isRecording;
@property (nonatomic,assign) BOOL isMetronomeRunning;
@property (nonatomic,strong) AVAudioPlayerNode *playerNode;

//节拍器相关
//bpm
@property (nonatomic,assign) int tempoBPM;
//每小节有几拍
@property (nonatomic,assign) int beatToTheBar;
//以几分音符为一拍
@property (nonatomic,assign) int noteValue;

+(AudioEngine *)sharedEngine;

- (void)stopEngine;
- (void)unitSampler:(AVAudioUnitSampler *)unitSampler loadSoundBankInstrumentAtURL:(NSURL *)soundFontFileURL;
- (void)initInstrumentsUnitSampler;
//- (void)startNote:(uint8_t)note withVelocity:(uint8_t)velocity onChannel:(uint8_t)channel;
//- (void)stopNote:(uint8_t)note onChannel:(uint8_t)channel;

- (void)initMetronome;
- (void)startMetronome;
- (void)stopMetronome;

- (void)refreshToneFrequency;
- (void)startGenerateTone;
- (void)stopGenerateTone;
- (void)startTuning;
- (void)stopTuning;

- (void)startRecording;
- (void)stopRecording;
- (void)startOrStopPlayingRecordAtURL:(NSURL *)url withCompletion:(void(^)(void))playCompletionHandler;

- (void)playOrStopAudioPlayerByURL:(NSURL *)audioEffectFileURL;
- (void)adjustAudioPlayerVolume:(float)volume byURL:(NSURL *)audioEffectFileURL;

@end
