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
    BOOL _isRecordPlaying;
    NSURL *_lastReocrdURL;
    void(^_lastRecordPlayCompletionHandler)(void);
}

@property (nonatomic,strong) AVAudioEngine *engine;

//调音器
@property (nonatomic,strong) AVAudioPCMBuffer *audioBuffer;
@property (nonatomic,strong) AVAudioFormat *audioFormat;
//当前基准音频率
@property (nonatomic,assign) float currentFrequency;
//傅立叶变换过滤获取声音频率工具类
@property (nonatomic,strong) EZAudioFFTRolling *fft;

//音频合成器
@property (nonatomic,strong) NSMutableDictionary<NSURL*,AVAudioPlayerNode*> *audioEffectPlayerDict;

//节拍器
@property (nonatomic,strong) AVAudioUnitSampler *metronomeNode;

@end

static vDSP_Length const FFTViewControllerFFTWindowSize = 4096;
static AVAudioFrameCount kSamplesPerBuffer = 44100;
static float unitVelocity;
@implementation AudioEngine
static AudioEngine *sharedEngine = nil;
//单例
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

        [self.engine attachNode:self.playerNode];
        [self.engine connect:self.playerNode to:self.engine.mainMixerNode fromBus:0 toBus:2 format:self.audioFormat];
        _isGeneratingTone = NO;
        _isTuning = NO;
        _isMetronomeValueChanged = NO;
        self.tempoBPM = 100;
        self.beatToTheBar = 1;
        self.noteValue = 4;
        
        _isRecordPlaying    = NO;
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
//初始化乐器演奏模块
- (void)initInstrumentsUnitSampler{
        self.instrumentsNode = [[AVAudioUnitSampler alloc] init];
    [self.engine attachNode:self.instrumentsNode];
    [self.engine connect:self.instrumentsNode to:self.engine.mainMixerNode fromBus:0 toBus:0 format:self.audioFormat];
    NSURL *soundFontFileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Grand Piano" ofType:@"sf2"]];
    [self unitSampler:self.instrumentsNode loadSoundBankInstrumentAtURL:soundFontFileURL];
    
    [self startEngine];
}

#pragma mark for metronome
//节拍器相关
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
//节拍器初始化
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
    _metronomeCount++;
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
    uint8_t data1;
    //按拍数区分强弱次强音
    switch (_metronomeCount%self.beatToTheBar) {
        case 1:
            data1 = 2;
            break;
        case 2:
            data1 = 1;
            break;
        case 3:
            if (self.beatToTheBar==4)
                data1 = 0;
            else
                data1 = 1;
            break;
        case 4:
            data1 = 0;
            break;
        case 0:
            if (self.beatToTheBar==1)
                data1 = 2;
            else
                data1 = 1;
            break;
        default:
            data1 = 1;
            break;
    }
    [self.metronomeNode sendMIDIEvent:'\x90' data1:data1 data2:50];
    if (_metronomeCount==self.beatToTheBar) {
        _metronomeCount = 0;
    }
}
//加载sf文件
- (void)unitSampler:(AVAudioUnitSampler *)unitSampler loadSoundBankInstrumentAtURL:(NSURL *)soundFontFileURL{
    uint8_t melodicBank = kAUSampler_DefaultMelodicBankMSB;
    uint8_t gmHarpsichord = 0;
    NSError *error;
    BOOL result = [unitSampler loadSoundBankInstrumentAtURL:soundFontFileURL program:gmHarpsichord bankMSB:melodicBank bankLSB:0 error:&error];
    NSAssert(result, @"Unable to set the preset property on the Sampler. Error %@", [error localizedDescription]);
}

#pragma mark record
//录音
- (void)startRecording{
    if (!_isRecording) {
        NSError *error;
        NSString *fileName = [NSString stringWithFormat:@"%.f.wav",[[NSDate date] timeIntervalSince1970]];
        NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:fileName]];
        
        AVAudioFile *mixerOutputFile = [[AVAudioFile alloc] initForWriting:fileURL settings:[[self.engine.mainMixerNode outputFormatForBus:0] settings] error:&error];
        NSAssert(mixerOutputFile != nil, @"mixerOutputFile is nil, %@", [error localizedDescription]);
        [self.engine.mainMixerNode installTapOnBus:0 bufferSize:4096 format:[self.engine.mainMixerNode outputFormatForBus:0] block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            
            NSError *error;
            BOOL success = NO;
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
        _isRecording = NO;
    }
}
//播放录音
- (void)startOrStopPlayingRecordAtURL:(NSURL *)url withCompletion:(void(^)(void))playCompletionHandler{
    if (_isRecordPlaying) {
        _isRecordPlaying = NO;
        self.playerNode.volume = 1;
        [self.playerNode stop];
//        playCompletionHandler();
        if (_lastRecordPlayCompletionHandler) {
            _lastRecordPlayCompletionHandler();
        }
    }
    if (url!=_lastReocrdURL) {
        _lastRecordPlayCompletionHandler = playCompletionHandler;
        _isRecordPlaying = YES;
        _lastReocrdURL = url;
        NSURL *fileURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingString:@"record.wav"]];
        NSError *error ;
        AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&error];
        [self.audioEffectPlayerDict enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull key, AVAudioPlayerNode * _Nonnull obj, BOOL * _Nonnull stop) {
            [obj stop];
        }];
        [self stopMetronome];
        [self.playerNode scheduleFile:file atTime:nil completionHandler:^{
            //这个回掉不在主线程里
            if (_isRecordPlaying) {
                dispatch_sync(dispatch_get_main_queue(), playCompletionHandler);
                _isRecordPlaying = NO;
                _lastReocrdURL = NULL;
            }
    
        }];
        [self.playerNode play];
    }
}

#pragma mark- for tuner

- (void)attachAndConnectNode{
    [self.engine attachNode:self.playerNode];
}
//基准音播放
- (void)startGenerateTone{
    if (!_isGeneratingTone) {
        [self refreshToneFrequency];
        [self startEngine];
        [self.playerNode scheduleBuffer:self.audioBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [self.playerNode play];
        _isGeneratingTone = YES;
    }
}

- (void)stopGenerateTone{
    if (_isGeneratingTone) {
        [self.playerNode stop];
        _isGeneratingTone = NO;
        
    }
}
//麦克风调音
- (void)startTuning{
    if (!_isTuning) {
        if (!self.fft) {
            self.fft = [EZAudioFFTRolling fftWithWindowSize:FFTViewControllerFFTWindowSize sampleRate:44100 delegate:self];
        }
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
        _isTuning = NO;
        self.engine.mainMixerNode.outputVolume = 1;
    }
}

- (void)refreshToneFrequency{
    float newFrequency;
    if (_delegate){
        if ([_delegate respondsToSelector:@selector(requestForToneFrequency)]) {
            newFrequency = [_delegate requestForToneFrequency];
        }
        if ([_delegate respondsToSelector:@selector(requestForToneVolume)]) {
            self.playerNode.volume = [_delegate requestForToneVolume];
        }
    }
    if (newFrequency!=_currentFrequency) {
        _currentFrequency = newFrequency;
        
        float sampleTime = 0;
        //手动设置audioBuffer频率
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
//音乐合成相关
- (NSMutableDictionary *)audioEffectPlayerDict{
    if (_audioEffectPlayerDict == NULL) {
        _audioEffectPlayerDict = [[NSMutableDictionary alloc] init];
    }
    return _audioEffectPlayerDict;
}

- (void)playOrStopAudioPlayerByURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *currentPlayerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    if (currentPlayerNode) {
        if (currentPlayerNode.isPlaying) {
            [currentPlayerNode pause];
        }else{
            [currentPlayerNode play];
            [self.audioEffectPlayerDict enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull key, AVAudioPlayerNode * _Nonnull obj, BOOL * _Nonnull stop) {
                if (currentPlayerNode!=obj) {
                    if ([obj isPlaying]) {
                        [obj pause];
//                        [obj play];
                    }
                }
            }];
        }
    }else
        [self addAudioEffectPlayerByURL:audioEffectFileURL];

}

- (void)removeAudioEffectPlayerByURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *playerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    [playerNode stop];
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
//音量调节
-(void)adjustAudioPlayerVolume:(float)volume byURL:(NSURL *)audioEffectFileURL{
    AVAudioPlayerNode *playerNode = self.audioEffectPlayerDict[audioEffectFileURL];
    playerNode.volume = volume;
}

#pragma mark AVAudioSession
//audio session初始化
- (void)initAVAudioSession
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    
    // set the session category
    BOOL success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}


#pragma FFT delegate -mark
//傅立叶获取声音频率
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
