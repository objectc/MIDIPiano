//
//  ViewController.m
//  TestMidi
//
//  Created by Tab on 18/10/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "PianoViewController.h"
#import "MidiAudioManager.h"
#import "PianoKey.h"
@interface PianoViewController()<PianoKeyDelegate,UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,weak)PianoKey *lastKey;
@property(nonatomic)int velocity;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;
@property (weak, nonatomic) IBOutlet UITableView *soundFontTableView;
@property (nonatomic,strong) NSArray<NSURL *> *soundFontURLArray;
@end

@implementation PianoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initPiano];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)initPiano{
    self.velocity = 50;
    self.velocityLabel.text = [NSString stringWithFormat:@"%d",self.velocity];
    [MidiAudioManager sharedManager];
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            PianoKey *key = (PianoKey*)subView;
        NSString *btnTitle = [NSString stringWithUTF8String:noteForMidiNumber(key.tag)];
        [key setTitle:btnTitle forState:UIControlStateNormal];
        }
    }
    
    self.soundFontURLArray = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"sf2" subdirectory:nil];
}

/*
- (void)addGestureToBtn{
    
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            
//            UISwipeGestureRecognizer *panGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(panGesAction:)];
            PianoKey *btn = (PianoKey *)subView;
            btn.delegate = self;
//            [btn addTarget:self action:@selector(keyPressed2:) forControlEvents:UIControlEventTouchDragEnter];
//            [btn addGestureRecognizer:panGes];
        }
    }
}


- (IBAction)keyPressed2:(id)sender {
    UIButton *pressedBtn = sender;
    NSString *btnTitle = [NSString stringWithUTF8String:noteForMidiNumber(pressedBtn.tag)];
    [pressedBtn setTitle:btnTitle forState:UIControlStateNormal];
    MidiAudioManager *midiManager = [MidiAudioManager sharedManager];
    [midiManager playNote:(UInt32)pressedBtn.tag];
}

- (IBAction)keyPressed:(id)sender {
//    UIButton *pressedBtn = sender;
//    NSString *btnTitle = [NSString stringWithUTF8String:noteForMidiNumber(pressedBtn.tag)];
//    [pressedBtn setTitle:btnTitle forState:UIControlStateNormal];
//    MidiAudioManager *midiManager = [MidiAudioManager sharedManager];
//    [midiManager playNote:(UInt32)pressedBtn.tag];
    
    MusicDeviceNoteParams note;
    note.argCount = 2;
    note.mPitch = 45;
    note.mVelocity = 1;
    
    [[MidiAudioManager sharedManager] startPlayNote:note];
}
*/


const char * noteForMidiNumber(int midiNumber) {
    
    const char * const noteArraySharps[] = {"", "", "", "", "", "", "", "", "", "", "", "",
        "C0", "C#0", "D0", "D#0", "E0", "F0", "F#0", "G0", "G#0", "A0", "A#0", "B0",
        "C1", "C#1", "D1", "D#1", "E1", "F1", "F#1", "G1", "G#1", "A1", "A#1", "B1",
        "C2", "C#2", "D2", "D#2", "E2", "F2", "F#2", "G2", "G#2", "A2", "A#2", "B2",
        "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3", "G#3", "A3", "A#3", "B3",
        "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4", "A#4", "B4",
        "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5",
        "C6", "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6", "A6", "A#6", "B6",
        "C7", "C#7", "D7", "D#7", "E7", "F7", "F#7", "G7", "G#7", "A7", "A#7", "B7",
        "C8", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""};
    
    return noteArraySharps[midiNumber];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%d fingers",touches.count);
    UITouch *touch = [touches anyObject];
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            PianoKey *key = (PianoKey*)subView;
            if ([key pointInside:[touch locationInView:self.view] withEvent:event]) {
                MusicDeviceNoteParams note = [self getNoteByPianoKey:key];
                [[MidiAudioManager sharedManager] startPlayNote:note];
                self.lastKey = key;
                break;
            }
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            PianoKey *key = (PianoKey*)subView;
            if ([key pointInside:[touch locationInView:self.view] withEvent:event]) {
                if (self.lastKey!=key) {
                    if (self.lastKey) {
                        [[MidiAudioManager sharedManager] stopPlayNote];
                    }
                    MusicDeviceNoteParams note = [self getNoteByPianoKey:key];
                    [[MidiAudioManager sharedManager] startPlayNote:note];
                    self.lastKey = key;
                    
                }else{
                    
                }
                break;
            }
        }
    }
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [touches anyObject];
//    for (NSObject* subView in [self.view subviews]) {
//        if ([subView isKindOfClass:[PianoKey class]]) {
//            PianoKey *key = (PianoKey*)subView;
//            if ([key pointInside:[touch locationInView:self.view] withEvent:event]) {
//                if (self.lastKey==key) {
//                    [[MidiAudioManager sharedManager] stopPlayNote];
//                    break;
//                }
//            }
//        }
//    }
    if (self.lastKey) {
                            [[MidiAudioManager sharedManager] stopPlayNote];
    }
    
}

- (MusicDeviceNoteParams)getNoteByPianoKey:(PianoKey *)key{
//    NSValue *noteValue = [self.noteDict objectForKey:[NSNumber numberWithInteger:key.tag]];
    MusicDeviceNoteParams note;
//    if (false) {
//        MusicDeviceNoteParams *oldNote;
//        oldNote = [noteValue pointerValue];
////        [noteValue getValue:<#(nonnull void *)#>];
//        [self.noteDict removeObjectForKey:[NSNumber numberWithInteger:key.tag]];
//    }else{
        note.argCount = 2;
        note.mPitch = key.tag;
        note.mVelocity = self.velocity;
        NSValue *noteValue = [NSValue valueWithPointer:&note];
//        [self.noteDict setObject:noteValue forKey:[NSNumber numberWithInteger:key.tag]];
//    }
    return note;
    
}
- (IBAction)switchSoundFont:(id)sender {
    self.soundFontTableView.hidden = false;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.soundFontURLArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellIdentifier  = @"SFCELL";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = self.soundFontURLArray[indexPath.row].lastPathComponent;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[MidiAudioManager sharedManager] loadFromDLSOrSoundFont:self.soundFontURLArray[indexPath.row] withPatch:0];
    self.soundFontTableView.hidden = YES;

}

- (IBAction)adjustVelocity:(id)sender{
    UIButton *btn = (UIButton *)sender;
    if (btn.tag==0 && self.velocity>0) {
        self.velocity -=10;
    }else if(self.velocity<100)
        self.velocity +=10;
    self.velocityLabel.text = [NSString stringWithFormat:@"%d",self.velocity];
}

- (void)pianoKey:(PianoKey *)pianoKey touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
}
- (void)pianoKey:(PianoKey *)pianoKey touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
}
- (void)pianoKey:(PianoKey *)pianoKey touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}
@end
