//
//  TunerViewController.m
//  MidiPiano
//
//  Created by Tab on 01/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "TunerViewController.h"

@interface TunerViewController ()

@end

@implementation TunerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//-(void)loadAudio{
    
//    extAFNumChannels = 2;
//    
//    OSStatus err;
//    AudioStreamBasicDescription fileFormat;
//    UInt32 propSize = sizeof(fileFormat);
//    memset(&fileFormat, 0, sizeof(AudioStreamBasicDescription));
//    
//    err = ExtAudioFileGetProperty(extAFRef, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
//    if(err != noErr) {
//        NSLog(@"Cannot get audio file properties");
//        return;
//    }
//    
//    Float64 sampleRate = 44100.0;
//    
//    float startingSample = (44100.0 * playProgress * lengthInSeconds);
//    
//    AudioStreamBasicDescription clientFormat;
//    propSize = sizeof(clientFormat);
//    
//    memset(&clientFormat, 0, sizeof(AudioStreamBasicDescription));
//    clientFormat.mFormatID = kAudioFormatLinearPCM;
//    clientFormat.mSampleRate = sampleRate;
//    clientFormat.mFormatFlags = kAudioFormatFlagIsFloat;
//    clientFormat.mChannelsPerFrame = extAFNumChannels;
//    clientFormat.mBitsPerChannel     = sizeof(float) * 8;
//    clientFormat.mFramesPerPacket    = 1;
//    clientFormat.mBytesPerFrame      = extAFNumChannels * sizeof(float);
//    clientFormat.mBytesPerPacket     = extAFNumChannels * sizeof(float);
//    
//    err = ExtAudioFileSetProperty(extAFRef, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
//    if(err != noErr) {
//        NSLog(@"Couldn't convert audio file to PCM format");
//        return;
//    }
//    
//    err = ExtAudioFileSeek(extAFRef, startingSample);
//    if(err != noErr) {
//        NSLog(@"Error in seeking in file");
//        return;
//    }
//    
//    float *returnData = (float *)malloc(sizeof(float) * 1024);
//    
//    AudioBufferList bufList;
//    bufList.mNumberBuffers = 1;
//    bufList.mBuffers[0].mNumberChannels = extAFNumChannels; // Always 2 channels in this example
//    bufList.mBuffers[0].mData = returnData; // data is a pointer (float*) to our sample buffer
//    bufList.mBuffers[0].mDataByteSize = 1024 * sizeof(float);
//    
//    UInt32 loadedPackets = 1024;
//    
//    err = ExtAudioFileRead(extAFRef, &loadedPackets, &bufList);
//    if(err != noErr) {
//        NSLog(@"Error in reading the file");
//        return;
//    }
//    
//    freq.fourierData = [self computeFFTForData:returnData forSampleSize:1024];
//    [freq setNeedsDisplay];
//    
//}
//
//-(float *)computeFFTForData:(float *)data forSampleSize:(int)bufferFrames{
//    
//    int bufferLog2 = round(log2(bufferFrames));
//    FFTSetup fftSetup = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
//    float *hammingWindow = (float *)malloc(sizeof(float) * bufferFrames);
//    vDSP_hamm_window(hammingWindow, bufferFrames, 0);
//    float outReal[bufferFrames / 2];
//    float outImaginary[bufferFrames / 2];
//    COMPLEX_SPLIT out = { .realp = outReal, .imagp = outImaginary };
//    vDSP_vmul(data, 1, hammingWindow, 1, data, 1, bufferFrames);
//    vDSP_ctoz((COMPLEX *)data, 2, &out, 1, bufferFrames / 2);
//    vDSP_fft_zrip(fftSetup, &out, 1, bufferLog2, FFT_FORWARD);
//    
//    //print out data
//    //    for(int i = 1; i < bufferFrames / 2; i++){
//    //        float frequency = (i * 44100.0)/bufferFrames;
//    //        float magnitude = sqrtf((out.realp[i] * out.realp[i]) + (out.imagp[i] * out.imagp[i]));
//    //        float magnitudeDB = 10 * log10(out.realp[i] * out.realp[i] + (out.imagp[i] * out.imagp[i]));
//    //        NSLog(@"Bin %i: Magnitude: %f Magnitude DB: %f  Frequency: %f Hz", i, magnitude, magnitudeDB, frequency);
//    //    }
//    
//    //NSLog(@"\nSpectrum\n");
//    //    for(int k = 0; k < bufferFrames / 2; k++){
//    //        NSLog(@"Frequency %f Real: %f Imag: %f", (k * 44100.0)/bufferFrames, out.realp[k], out.imagp[k]);
//    //    }
//    
//    float *mag = (float *)malloc(sizeof(float) * bufferFrames/2);
//    float *phase = (float *)malloc(sizeof(float) * bufferFrames/2);
//    float *magDB = (float *)malloc(sizeof(float) * bufferFrames/2);
//    
//    vDSP_zvabs(&out, 1, mag, 1, bufferFrames/2);
//    vDSP_zvphas(&out, 1, phase, 1, bufferFrames/2);
//    
//    //NSLog(@"\nMag / Phase\n");
//    for(int k = 1; k < bufferFrames/2; k++){
//        float magnitudeDB = 10 * log10(out.realp[k] * out.realp[k] + (out.imagp[k] * out.imagp[k]));
//        magDB[k] = magnitudeDB;
//        //NSLog(@"Frequency: %f Magnitude DB: %f", (k * 44100.0)/bufferFrames, magnitudeDB);
//        if(magDB[k] > freq.largestMag){
//            freq.largestMag = magDB[k];
//        }
//        //NSLog(@"Frequency: %f Mag: %f Phase: %f", (k * 44100.0)/bufferFrames, mag[k], phase[k]);
//    }
//    
//    return magDB;
//}
//
//
@end
