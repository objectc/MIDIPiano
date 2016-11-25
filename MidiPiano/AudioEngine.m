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
    BOOL _isTuning;
    BOOL _isGeneratingTone;
    BOOL _isMetronomeValueChanged;
    BOOL _isNeedToStopMetronome;
    int  _metronomeCount;
    AVAudioFile *_currentMetronomeFile;
}

@property (nonatomic,strong) AVAudioEngine *engine;
//调音器
@property (nonatomic,strong) AVAudioPlayerNode *playerNode;
@property (nonatomic,strong) AVAudioPCMBuffer *audioBuffer;
@property (nonatomic,strong) AVAudioFormat *audioFormat;
@property (nonatomic,assign) float currentFrequency;
@property (nonatomic,strong) EZAudioFFTRolling *fft;
@property (nonatomic,strong) NSMutableDictionary<NSURL*,AVAudioPlayerNode*> *audioEffectPlayerDict;
@property (nonatomic,strong) NSMutableDictionary<NSURL*,AVAudioPlayerNode*> *audioEffectPlayerReuseDict;

//节拍器
@property (nonatomic,strong) AVAudioUnitSampler *metronomeNode;

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
        self.engine.inputNode;
        self.playerNode = [[AVAudioPlayerNode alloc] init];
        self.audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
        self.audioBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.audioFormat frameCapacity:kSamplesPerBuffer];
        unitVelocity = 2.0 * M_PI / self.audioFormat.sampleRate;
//        self.currentFrequency = 440.0;
//        [self refreshToneFrequency];
        
//        [self attachAndConnectNode];
        [self.engine attachNode:self.playerNode];
        [self.engine connect:self.playerNode to:self.engine.mainMixerNode fromBus:0 toBus:2 format:self.audioFormat];
        _isGeneratingTone = NO;
        _isTuning = NO;
        _isMetronomeValueChanged = NO;
        self.tempoBPM = 100;
        self.beatToTheBar = 1;
        self.noteValue = 4;
    }
    return self;
}

#pragma mark AudioEngine
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

#pragma mark for instuments
- (void)initInstrumentsUnitSampler{
        self.instrumentsNode = [[AVAudioUnitSampler alloc] init];
    [self.engine attachNode:self.instrumentsNode];
    [self.engine connect:self.instrumentsNode to:self.engine.mainMixerNode fromBus:0 toBus:0 format:self.audioFormat];
    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Grand Piano" ofType:@"sf2"]];
    [self unitSampler:self.instrumentsNode loadSoundBankInstrumentAtURL:soundFontFileURL];
    
    [self startEngine];
}

#pragma mark for metronome
- (void)setTempoBPM:(int)tempoBPM{
    _tempoBPM = tempoBPM;
    _isMetronomeValueChanged = YES;
    
}
- (void)setBeatToTheBar:(int)beatToTheBar{
    _beatToTheBar = beatToTheBar;
    _isMetronomeValueChanged = YES;
}
- (void)setNoteValue:(int)noteValue{
    _noteValue = noteValue;
    _isMetronomeValueChanged = YES;
}

- (void)initMetronome{
    self.metronomeNode = [[AVAudioUnitSampler alloc] init];
    [self.engine attachNode:self.metronomeNode];
    [self.engine connect:self.metronomeNode to:self.engine.mainMixerNode fromBus:0 toBus:1 format:self.audioFormat];
    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"metronome" ofType:@"sf2"]];
    [self unitSampler:self.metronomeNode loadSoundBankInstrumentAtURL:soundFontFileURL];
    
    [self startEngine];
}

- (void)startMetronome{
    if (self.metronomeNode==NULL) {
        [self initMetronome];
    }
    NSTimeInterval interval = 60.0/self.tempoBPM/(self.noteValue/4);
    _metronomeCount = 0;
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(loopMetronome:) userInfo:nil repeats:YES];
    _isNeedToStopMetronome = NO;
    self.isMetronomeRunning = YES;
}
- (void)stopMetronome{
    _isNeedToStopMetronome = YES;
    self.isMetronomeRunning = NO;
}

- (void)loopMetronome:(NSTimer *)timer{
    if (_isNeedToStopMetronome) {
        [timer invalidate];
        return;
    }
    if (_isMetronomeValueChanged) {
        _isMetronomeValueChanged = NO;
        [timer invalidate];
        [self startMetronome];
        return;
    }
    uint8_t data1 = _metronomeCount%self.beatToTheBar==0?0:1;
    
    [self.metronomeNode sendMIDIEvent:'\x90' data1:data1 data2:50];
    _metronomeCount++;
//    [self.metronomeNode startNote:0 withVelocity:100 onChannel:2];
}

- (void)unitSampler:(AVAudioUnitSampler *)unitSampler loadSoundBankInstrumentAtURL:(NSURL *)soundFontFileURL{
    uint8_t melodicBank = kAUSampler_DefaultMelodicBankMSB;
    uint8_t gmHarpsichord = 0;
    NSError *error;
    BOOL result = [unitSampler loadSoundBankInstrumentAtURL:soundFontFileURL program:gmHarpsichord bankMSB:melodicBank bankLSB:0 error:&error];
    NSAssert(result, @"Unable to set the preset property on the Sampler. Error %@", [error localizedDescription]);
}

#pragma mark record

- (void)startRecording{
    if (!_isRecording) {
        NSError *error;
        
        NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"record.wav"]];
        
        AVAudioFile *mixerOutputFile = [[AVAudioFile alloc] initForWriting:fileURL settings:[[self.engine.mainMixerNode outputFormatForBus:0] settings] error:&error];
        NSAssert(mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
//        [self.engine connect:self.engine.inputNode to:self.engine.mainMixerNode fromBus:0 toBus:3 format:self.audioFormat];
        [self.engine.mainMixerNode installTapOnBus:0 bufferSize:4096 format:[self.engine.mainMixerNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            
            NSError *error;
            BOOL success = NO;
            
            
            // as AVAudioPCMBuffer's are delivered this will write sequentially. The buffer's frameLength signifies how much of the buffer is to be written
            // IMPORTANT: The buffer format MUST match the file's processing format which is why outputFormatForBus: was used when creating the AVAudioFile object above
            success = [mixerOutputFile writeFromBuffer:buffer error:&error];
            NSAssert(success, @"error writing buffer data to file, %@", [error localizedDescription]);
            
        }];
        [self startEngine];
        _isRecording = YES;
    }
}

- (void)stopRecording{
    if (_isRecording) {
        [self.engine.mainMixerNode removeTapOnBus:0];
//        [self.engine disconnectNodeInput:self.engine.inputNode];
//        [self.engine stop];
        _isRecording = NO;
    }
}

- (void)playRecord{
    NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"record.wav"]];
    NSError *error ;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:fileURL error:&error];
    [self.audioEffectPlayerDict enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull key, AVAudioPlayerNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj stop];
    }];
    [self stopMetronome];
    [self.playerNode scheduleFile:file atTime:nil completionHandler:nil];
    [self.playerNode play];

}

#pragma mark- for tuner

- (void)attachAndConnectNode{
    [self.engine attachNode:self.playerNode];
}

- (void)startGenerateTone{
    if (!_isGeneratingTone) {
        [self refreshToneFrequency];
//        [self.engine connect:self.playerNode to:self.engine.mainMixerNode format:self.audioFormat];
        [self startEngine];
        self.engine.mainMixerNode.outputVolume = 1;
        [self.playerNode scheduleBuffer:self.audioBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [self.playerNode play];
        _isGeneratingTone = YES;
    }
}

- (void)stopGenerateTone{
    if (_isGeneratingTone) {
        [self.playerNode stop];
//        [self stopEngine];
//        [self.engine disconnectNodeInput:self.playerNode];
        _isGeneratingTone = NO;
        
    }
}

- (void)startTuning{
    if (!_isTuning) {
        if (!self.fft) {
            self.fft = [EZAudioFFTRolling fftWithWindowSize:FFTViewControllerFFTWindowSize sampleRate:44100 delegate:self];
        }
//        [self.engine connect:self.engine.inputNode to:self.engine.mainMixerNode fromBus:0 toBus:3 format:self.audioFormat];
        [self.engine.inputNode installTapOnBus:0 bufferSize:4096 format:self.audioFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            [self.fft computeFFTWithBuffer:buffer.floatChannelData[0] withBufferSize:4096];
            
        }];
        self.engine.mainMixerNode.outputVolume = 0;
        [self startEngine];
        _isTuning = YES;
    }
}

- (void)stopTuning{
    if (_isTuning) {
        [self.engine.inputNode removeTapOnBus:0];
//        [self stopEngine];
        _isTuning = NO;
        self.engine.mainMixerNode.outputVolume = 1;
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
        }else{
            [playerNode play];
        }
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
AVAudioNodeBus nextAvailableInputBus = 5;
-(void)addAudioEffectPlayerByURL:(NSURL *)audioEffectFileURL{
    NSError *error;
    AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
    playerNode.volume = 0.5;
    AVAudioFile *audioEffectFile = [[AVAudioFile alloc] initForReading:audioEffectFileURL error:&error];
    AVAudioPCMBuffer *fileBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioEffectFile.processingFormat frameCapacity:(AVAudioFrameCount)[audioEffectFile length]];
    [audioEffectFile readIntoBuffer:fileBuffer error:&error];
    self.audioEffectPlayerDict[audioEffectFileURL] = playerNode;
    [self.engine attachNode:playerNode];
    [self.engine connect:playerNode to:self.engine.mainMixerNode fromBus:0 toBus:nextAvailableInputBus format:fileBuffer.format];
    ++nextAvailableInputBus;
    [playerNode scheduleBuffer:fileBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops   completionHandler:nil];
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
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
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
    
    NSURL *url =[NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"mixerOutput.caf"]];
    
    
    NSDictionary *settings=[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithFloat:8000.0],AVSampleRateKey,
                            [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                            [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                            [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                            [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                            [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                            nil];
    
    
    
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
