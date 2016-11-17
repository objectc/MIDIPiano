//
//  AudioEngine.h
//  MidiPiano
//
//  Created by Tab on 10/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioEngine;
@protocol ToneGeneratorDelegate <NSObject>
- (float) requestForToneFrequency;

@end

@protocol FFTDelegate <NSObject>

- (void) returnMaxFrequency:(float)maxFrequency;

@end

@interface AudioEngine : NSObject

@property(nonatomic,weak) id<ToneGeneratorDelegate,FFTDelegate>delegate;
+(id)sharedEngine;

- (void)stopEngine;

- (void)refreshToneFrequency;
- (void)startGenerateTone;
- (void)stopGenerateTone;
- (void)startRecording;
- (void)stopRecording;

- (void)playOrStopAudioPlayerByURL:(NSURL *)audioEffectFileURL;
- (void)adjustAudioPlayerVolume:(float)volume byURL:(NSURL *)audioEffectFileURL;

@end
