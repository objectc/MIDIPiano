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

- (void)refreshToneFrequency;
- (void)startGenerateTone;
- (void)stopGenerateTone;
- (void)startRecording;
- (void)stopRecording;

@end