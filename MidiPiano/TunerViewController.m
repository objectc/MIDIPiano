//
//  TunerViewController.m
//  MidiPiano
//
//  Created by Tab on 01/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "TunerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioEngine.h"

@interface TunerViewController ()<ToneGeneratorDelegate,FFTDelegate>
@property (weak, nonatomic) IBOutlet UILabel *playerFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *inputFrequencyLabel;
@property (nonatomic, strong)AudioEngine *audioEngine;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property (weak, nonatomic) IBOutlet UIStepper *frequencyStepper;
@property (weak, nonatomic) IBOutlet UISlider *toneVolumeSlider;

@end

@implementation TunerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.audioEngine = [AudioEngine sharedEngine];
    self.audioEngine.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.audioEngine stopTuning];
    [self.audioEngine stopGenerateTone];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)playAudioBtnAction:(id)sender {
    self.inputFrequencyLabel.text = @"";
    [self.audioEngine stopTuning];
    [self.audioEngine startGenerateTone];
}
- (IBAction)inputBtnAction:(id)sender {
    [self.audioEngine stopGenerateTone];
    [self.audioEngine startTuning];
}
- (IBAction)frequencySliderValueChangedAction:(id)sender {
    
    UISlider *slider = (UISlider *)sender;
    self.playerFrequencyLabel.text = [NSString stringWithFormat:@"%.f Hz",slider.value];
    self.frequencyStepper.value = slider.value;
    [self.audioEngine refreshToneFrequency];
}

- (IBAction)frequencyStepperValueChangedAction:(id)sender {
    
    UIStepper *stepper = (UIStepper *)sender;
    self.playerFrequencyLabel.text = [NSString stringWithFormat:@"%.f Hz",stepper.value];
    self.frequencySlider.value = stepper.value;
    [self.audioEngine refreshToneFrequency];
}
- (IBAction)toneVolumeSliderValueChangedAction:(id)sender {
    [self.audioEngine refreshToneFrequency];
}
- (float)requestForToneFrequency{
    return self.frequencySlider.value;
}

- (float)requestForToneVolume{
    return self.toneVolumeSlider.value;
}

- (void)returnMaxFrequency:(float)maxFrequency{
    self.inputFrequencyLabel.text =[NSString stringWithFormat:@"%.0f Hz",maxFrequency];
}

@end
