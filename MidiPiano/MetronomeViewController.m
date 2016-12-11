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
@property (weak, nonatomic) IBOutlet UITableView *switchTableView;

@end

@implementation MetronomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.beatStep.value = [AudioEngine sharedEngine].beatToTheBar;
    self.noteValueStep.value = [AudioEngine sharedEngine].noteValue;
    self.switchTableView.hidden = YES;
    [self refreshView];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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
    UIButton *btn = (UIButton *)sender;
    if ([AudioEngine sharedEngine].isMetronomeRunning) {
        [[AudioEngine sharedEngine] stopMetronome];
        [btn setTitle:@"开始" forState:UIControlStateNormal];
    }else{
        [[AudioEngine sharedEngine] startMetronome];
        [btn setTitle:@"停止" forState:UIControlStateNormal];
    }
}
- (IBAction)tempoBPMChnagedAction:(id)sender {
    [AudioEngine sharedEngine].tempoBPM = self.tempoBPMSlider.value;
    [self refreshView];
}

- (IBAction)showSwitchTableView:(id)sender {
    self.switchTableView.hidden = NO;
}

#pragma mark -table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell==nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"1/4";
            break;
        case 1:
            cell.textLabel.text = @"2/4";
            break;
        case 2:
            cell.textLabel.text = @"3/4";
            break;
        case 3:
            cell.textLabel.text = @"4/4";
            break;
        case 4:
            cell.textLabel.text = @"3/8";
            break;
        case 5:
            cell.textLabel.text = @"6/8";
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:{
            [AudioEngine sharedEngine].beatToTheBar = 1;
            [AudioEngine sharedEngine].noteValue = 4;
        }
            break;
        case 1:{
            [AudioEngine sharedEngine].beatToTheBar = 2;
            [AudioEngine sharedEngine].noteValue = 4;
            
        }
            break;
        case 2:{
            [AudioEngine sharedEngine].beatToTheBar = 3;
            [AudioEngine sharedEngine].noteValue = 4;
        }
            break;
        case 3:{
            [AudioEngine sharedEngine].beatToTheBar = 4;
            [AudioEngine sharedEngine].noteValue = 4;
        }
            break;
        case 4:{
            [AudioEngine sharedEngine].beatToTheBar = 3;
            [AudioEngine sharedEngine].noteValue = 8;
        }
            break;
        case 5:{
            [AudioEngine sharedEngine].beatToTheBar = 6;
            [AudioEngine sharedEngine].noteValue = 8;
        }
        default:
            break;
    }
    [self refreshView];
    self.switchTableView.hidden = YES;
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
