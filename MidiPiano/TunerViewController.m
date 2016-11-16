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

@end

@implementation TunerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.audioEngine = [AudioEngine sharedEngine];
    self.audioEngine.delegate = self;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)playAudioBtnAction:(id)sender {
    self.inputFrequencyLabel.text = @"";
    [self.audioEngine stopRecording];
    [self.audioEngine startGenerateTone];
}
- (IBAction)inputBtnAction:(id)sender {
    [self.audioEngine stopGenerateTone];
    [self.audioEngine startRecording];
}
- (IBAction)playerFrequencyChangedAction:(id)sender {
    UISlider *slider = (UISlider *)sender;
    self.playerFrequencyLabel.text = [NSString stringWithFormat:@"%.f Hz",slider.value];
    [self.audioEngine refreshToneFrequency];
}

- (float)requestForToneFrequency{
    return self.frequencySlider.value;
}

- (void)returnMaxFrequency:(float)maxFrequency{
    self.inputFrequencyLabel.text =[NSString stringWithFormat:@"%.0f Hz",maxFrequency];
}

@end
