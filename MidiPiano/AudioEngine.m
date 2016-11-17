//
//  AudioEngine.m
//  MidiPiano
//
//  Created by Tab on 10/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "AudioEngine.h"
@import AVFoundation;
@import Accelerate;

#import "EZAudioFFT.h"

@interface AudioEngine ()<EZAudioFFTDelegate>

{
    bool _isRecording;
    bool _isGeneratingTone;
}

@property (nonatomic,strong) AVAudioEngine *engine;
@property (nonatomic,strong) AVAudioPlayerNode *toneGeneratorNode;
@property (nonatomic,strong) AVAudioPCMBuffer *audioBuffer;
@property (nonatomic,strong) AVAudioFormat *audioFormat;
@property (nonatomic,assign) float currentFrequency;
@property (nonatomic,strong) EZAudioFFTRolling *fft;
@property (nonatomic,strong) NSMutableDictionary<NSURL*,AVAudioPlayerNode*> *audioEffectPlayerDict;
@property (nonatomic,strong) NSMutableDictionary<NSURL*,AVAudioPlayerNode*> *audioEffectPlayerReuseDict;

@end

static vDSP_Length const FFTViewControllerFFTWindowSize = 4096;
static AVAudioFrameCount kSamplesPerBuffer = 44100;
static float unitVelocity;
@implementation AudioEngine
static AudioEngine *sharedEngine = nil;

+ (AudioEngine *)sharedEngine
{
    @synchronized(self){
        if (nil == sharedEngine) {
            sharedEngine = [[AudioEngine alloc] init];
        }
    }
    return sharedEngine;
}
- (instancetype)init{
    if (self = [super init]) {
        [self initAVAudioSession];
        self.engine = [[AVAudioEngine alloc] init];
        self.toneGeneratorNode = [[AVAudioPlayerNode alloc] init];
        self.audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
        self.audioBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFormat frameCapacity:kSamplesPerBuffer];
        unitVelocity = 2.0 * M_PI / self.audioFormat.sampleRate;
//        self.currentFrequency = 440.0;
//        [self refreshToneFrequency];
        self.fft = [EZAudioFFTRolling fftWithWindowSize:FFTViewControllerFFTWindowSize sampleRate:44100 delegate:self];
        
        [self attachAndConnectNode];
        _isGeneratingTone = NO;
        _isRecording = NO;
    }
    return self;
}

#pragma mark- for tuner

- (void)attachAndConnectNode{
    [self.engine attachNode:self.toneGeneratorNode];
}

- (void)startEngine{
    if (!self.engine.isRunning) {
        NSError *error;
        BOOL success;
        success = [_engine startAndReturnError:&error];
        NSAssert(success, @"couldn't start engine, %@", [error localizedDescription]);
    }
}

- (void)stopEngine{
    if (self.engine.isRunning) {
        [_engine stop];
    }
}

- (void)startGenerateTone{
    if (!_isGeneratingTone) {
        [self refreshToneFrequency];
//        [self.engine connect:self.toneGeneratorNode to:self.engine.mainMixerNode format:self.audioFormat];
        [self.engine connect:self.toneGeneratorNode to:self.engine.mainMixerNode fromBus:0 toBus:0 format:self.audioFormat];
        [self startEngine];
        self.engine.mainMixerNode.outputVolume = 1;
        [self.toneGeneratorNode scheduleBuffer:self.audioBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [self.toneGeneratorNode play];
        _isGeneratingTone = YES;
    }
}

- (void)stopGenerateTone{
    if (_isGeneratingTone) {
        [self.toneGeneratorNode stop];
        [self.engine stop];
        [self.engine disconnectNodeInput:self.toneGeneratorNode];
        _isGeneratingTone = NO;
        
    }
}

- (void)startRecording{
    if (!_isRecording) {
        [self.engine connect:self.engine.inputNode to:self.engine.mainMixerNode fromBus:0 toBus:2 format:self.audioFormat];
        [self.engine.inputNode installTapOnBus:0 bufferSize:128 format:self.audioFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            [self.fft computeFFTWithBuffer:buffer.floatChannelData[0] withBufferSize:128];
            
        }];
        self.engine.mainMixerNode.outputVolume = 0;
        [self startEngine];
        _isRecording = YES;
    }
}

- (void)stopRecording{
    if (_isRecording) {
        [self.engine.inputNode removeTapOnBus:0];
        [self.engine disconnectNodeInput:self.engine.inputNode];
        [self.engine stop];
        _isRecording = NO;
    }
}

- (void)refreshToneFrequency{
    float newFrequency;
    if (_delegate && [_delegate respondsToSelector:@selector(requestForToneFrequency)]) {
        newFrequency = [_delegate requestForToneFrequency];
    }
    if (newFrequency!=_currentFrequency) {
        _currentFrequency = newFrequency;
        
        float sampleTime = 0;
        for (int sampleIndex = 0; sampleIndex < kSamplesPerBuffer; sampleIndex++){
            float modulatorAmplitude = 1;
            float modulatorVelocity = _currentFrequency *unitVelocity;
            double sample =  sin(modulatorVelocity * sampleTime);
            float * leftChannel =  self.audioBuffer.floatChannelData[0];
            float * rightChannel =  self.audioBuffer.floatChannelData[1];
            leftChannel[sampleIndex] = sample;
            rightChannel[sampleIndex] = sample;
            sampleTime++;
        }
        self.audioBuffer.frameLength = kSamplesPerBuffer;
    }
}

#pragma mark for audio mix

- (NSMutableDictionary *)audioEffectPlayerDict{
    if (_audioEffectPlayerDict == NULL) {
        _audioEffectPlayerDict = [[NSMutableDictionary alloc] init];
    }
    return _audioEffectPlayerDict;
}

- (NSMutableDictionary *)audioEffectPlayerReuseDict{
    if (_audioEffectPlayerReuseDict == NULL) {
        _audioEffectPlayerReuseDict = [[NSMutableDictionary alloc] init];
    }
    return _audioEffectPlayerReuseDict;
}

- (void)playOrStopAudioPlayerByURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *playerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    if (playerNode) {
        if (playerNode.isPlaying) {
            [playerNode pause];
        }else
            [playerNode play];
        
    }else
        [self addAudioEffectPlayerByURL:audioEffectFileURL];

}

- (void)removeAudioEffectPlayerByURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *playerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    [playerNode stop];
//    [self.engine disconnectNodeInput:playerNode];
//    [self.engine detachNode:playerNode ];
//    self.audioEffectPlayerReuseDict[audioEffectFileURL] = playerNode;
//    [self.audioEffectPlayerDict removeObjectForKey:audioEffectFileURL];
}
int playerCount = 0;
-(void)addAudioEffectPlayerByURL:(NSURL *)audioEffectFileURL{
    NSError *error;
    AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
    playerNode.volume = 0.5;
    AVAudioFile *audioEffectFile = [[AVAudioFile alloc] initForReading:audioEffectFileURL error:&error];
    AVAudioPCMBuffer *fileBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[audioEffectFile processingFormat] frameCapacity:(AVAudioFrameCount)[audioEffectFile length]];
    NSAssert([audioEffectFile readIntoBuffer:fileBuffer error:&error], @"PCMBuffer read error %@ into buffer, %@",[audioEffectFileURL description], [error localizedDescription]);
    self.audioEffectPlayerDict[audioEffectFileURL] = playerNode;
    [self.engine attachNode:playerNode];
    [self.engine connect:playerNode to:self.engine.mainMixerNode fromBus:0 toBus:playerCount++ format:fileBuffer.format];
    [playerNode scheduleBuffer:fileBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
    [self startEngine];
    [playerNode play];
}

-(void)adjustAudioPlayerVolume:(float)volume byURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *playerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    playerNode.volume = volume;
}

#pragma mark AVAudioSession

- (void)initAVAudioSession
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleMediaServicesReset:)
//                                                 name:AVAudioSessionMediaServicesWereResetNotification
//                                               object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
}


#pragma FFT delegate -mark
- (void)fft:(EZAudioFFT *)fft updatedWithFFTData:(float *)fftData bufferSize:(vDSP_Length)bufferSize{
    float maxFrequency = [fft maxFrequency];
    NSLog(@"%.2f",maxFrequency);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate && [_delegate respondsToSelector:@selector(returnMaxFrequency:)]) {
            [_delegate returnMaxFrequency:maxFrequency];
        }
    });
}

@end
