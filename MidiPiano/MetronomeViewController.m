//
//  MetronomeViewController.m
//  MidiPiano
//
//  Created by Tab on 23/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "MetronomeViewController.h"
#import "AudioEngine.h"

@interface MetronomeViewController ()
@property (weak, nonatomic) IBOutlet UIStepper *beatStep;
@property (weak, nonatomic) IBOutlet UIStepper *noteValueStep;
@property (weak, nonatomic) IBOutlet UILabel *tempoBPMLabel;
@property (weak, nonatomic) IBOutlet UILabel *beatLabel;
@property (weak, nonatomic) IBOutlet UILabel *noteValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *tempoBPMSlider;

@end

@implementation MetronomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.beatStep.value = [AudioEngine sharedEngine].beatToTheBar;
    self.noteValueStep.value = [AudioEngine sharedEngine].noteValue;
    [self refreshView];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshView{
    self.tempoBPMSlider.value = [AudioEngine sharedEngine].tempoBPM;
    self.tempoBPMLabel.text = [NSString stringWithFormat:@"%d",[AudioEngine sharedEngine].tempoBPM];
    self.beatLabel.text = [NSString stringWithFormat:@"%d",[AudioEngine sharedEngine].beatToTheBar];
    self.noteValueLabel.text = [NSString stringWithFormat:@"%d",[AudioEngine sharedEngine].noteValue];
}

- (IBAction)startOrStop:(id)sender {
    [[AudioEngine sharedEngine] startMetronome];
}
- (IBAction)tempoBPMChnagedAction:(id)sender {
    [AudioEngine sharedEngine].tempoBPM = self.tempoBPMSlider.value;
    [self refreshView];
}
- (IBAction)noteValueChangedAction:(id)sender {
    self.beatStep.maximumValue = self.noteValueStep.value;
    [AudioEngine sharedEngine].noteValue = self.noteValueStep.value;
    [self refreshView];
}

- (IBAction)beatChangedAction:(id)sender {
    [AudioEngine sharedEngine].beatToTheBar = self.beatStep.value;
    [self refreshView];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
