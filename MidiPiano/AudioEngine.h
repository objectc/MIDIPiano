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
- (float) requestForToneVolume;

@end

@protocol FFTDelegate <NSObject>

- (void) returnMaxFrequency:(float)maxFrequency;

@end

@interface AudioEngine : NSObject

@property (nonatomic,weak) id<ToneGeneratorDelegate,FFTDelegate>delegate;
//乐器
@property (nonatomic,strong) AVAudioUnitSampler *instrumentsNode;
//声音播放
@property (nonatomic,strong) AVAudioPlayerNode *playerNode;
@property (nonatomic,assign) BOOL isMIDIPlaying;
@property (nonatomic,assign) BOOL isRecording;
@property (nonatomic,assign) BOOL isMetronomeRunning;

//节拍器相关
//bpm
@property (nonatomic,assign) int tempoBPM;
//每小节有几拍
@property (nonatomic,assign) int beatToTheBar;
//以几分音符为一拍
@property (nonatomic,assign) int noteValue;

+(AudioEngine *)sharedEngine;

- (void)stopEngine;
//加载乐器声音文件
- (void)unitSampler:(AVAudioUnitSampler *)unitSampler loadSoundBankInstrumentAtURL:(NSURL *)soundFontFileURL;
//初始化乐器
- (void)initInstrumentsUnitSampler;

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
