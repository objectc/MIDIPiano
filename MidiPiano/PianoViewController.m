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
#import "AudioEffectTableViewCell.h"
#import "AudioEngine.h"
static MIDIClientRef _MIDIClientRef;
static MIDIPortRef _MIDIInputPortRef;
@interface PianoViewController()<PianoKeyDelegate,AudioEffectTableViewCellDelegate,UITableViewDelegate,UITableViewDataSource>{
}
@property(nonatomic,weak)PianoKey *lastKey;
@property(nonatomic,assign)int velocity;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;
@property (weak, nonatomic) IBOutlet UITableView *soundFontTableView;
@property (weak, nonatomic) IBOutlet UITableView *audioEffectTableView;
@property (weak, nonatomic) IBOutlet UITableView *recordFilesTableView;
@property (nonatomic,strong) NSArray<NSURL *> *soundFontURLArray;
@property (nonatomic,strong) NSArray<NSURL *> *audioEffectURLArray;
@property (nonatomic,strong) NSArray<NSURL *> *recordFilesURLArray;
@property (nonatomic,strong) NSMutableDictionary<NSIndexPath*,NSNumber *> *audioEffectTableViewData;
@property (nonatomic,strong) NSMutableDictionary<NSIndexPath*,NSNumber *> *recordFilesTableViewData;
@property (nonatomic,assign) BOOL isPlaying;
@end

static NSString *AudioEffectCellID = @"AudioEffectCell";

@implementation PianoViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initPiano];
    [self initAudioEffectModule];
    [self initMIDIClient];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)viewDidDisappear:(BOOL)animated{
//    [[AudioEngine sharedEngine] stopEngine];
    self.navigationController.navigationBarHidden = NO;
}
- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
}
- (void)initPiano{
    self.isPlaying = NO;
    self.velocity = 50;
    self.velocityLabel.text = [NSString stringWithFormat:@"%d",self.velocity];
//    [MidiAudioManager sharedManager];
    [[AudioEngine sharedEngine] initInstrumentsUnitSampler];
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            PianoKey *key = (PianoKey*)subView;
        NSString *btnTitle = [NSString stringWithUTF8String:noteForMidiNumber(key.tag)];
        [key setTitle:btnTitle forState:UIControlStateNormal];
        }
    }
    
    self.soundFontURLArray = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"sf2" subdirectory:nil];
    
}

- (void)initAudioEffectModule{
    self.audioEffectURLArray = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"m4a" subdirectory:nil];
    self.audioEffectTableViewData = [[NSMutableDictionary alloc] init];
    self.recordFilesTableViewData = [[NSMutableDictionary alloc] init];

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
    self.soundFontTableView.hidden = YES;
    self.audioEffectTableView.hidden = YES;
    self.recordFilesTableView.hidden = YES;
    UITouch *touch = [touches anyObject];
    for (NSObject* subView in [self.view subviews]) {
        if ([subView isKindOfClass:[PianoKey class]]) {
            PianoKey *key = (PianoKey*)subView;
            if ([key pointInside:[touch locationInView:self.view] withEvent:event]) {
//                MusicDeviceNoteParams note = [self getNoteByPianoKey:key];
//                [[MidiAudioManager sharedManager] startPlayNote:note];
                [[AudioEngine sharedEngine].instrumentsNode startNote:key.tag withVelocity:self.velocity onChannel:2];
//                [[AudioEngine sharedEngine] startMetronome];
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
                        [[AudioEngine sharedEngine].instrumentsNode stopNote:self.lastKey.tag onChannel:2];
                    }
                    [[AudioEngine sharedEngine].instrumentsNode startNote:key.tag withVelocity:self.velocity onChannel:2];
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
//                            [[MidiAudioManager sharedManager] stopPlayNote];
        [[AudioEngine sharedEngine].instrumentsNode stopNote:self.lastKey.tag onChannel:2];
        self.lastKey = nil;
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
//        NSValue *noteValue = [NSValue valueWithPointer:&note];
//        [self.noteDict setObject:noteValue forKey:[NSNumber numberWithInteger:key.tag]];
//    }
    return note;
    
}

#pragma mark Sound Font
- (IBAction)switchSoundFont:(id)sender {
    self.soundFontTableView.hidden = false;
}



#pragma mark Mix AudioEffect
- (IBAction)toggleAudioEffectAction:(id)sender {
    self.audioEffectTableView.hidden = !self.audioEffectTableView.hidden;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.soundFontTableView) {
        return self.soundFontURLArray.count;
    }else if(tableView == self.audioEffectTableView){
        return self.audioEffectURLArray.count;
    }else if (tableView == self.recordFilesTableView){
        return self.recordFilesURLArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if (tableView == self.soundFontTableView) {
        static NSString * cellIdentifier  = @"SFCELL";
         cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.textLabel.text = self.soundFontURLArray[indexPath.row].lastPathComponent;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }else if (tableView == self.audioEffectTableView){
        cell = [self.audioEffectTableView dequeueReusableCellWithIdentifier:AudioEffectCellID forIndexPath:indexPath];
//        ((AudioEffectTableViewCell *)cell).delegate = self;
        ((AudioEffectTableViewCell *)cell).titleLabel.text = [self.audioEffectURLArray[indexPath.row].lastPathComponent stringByDeletingPathExtension];
//        cell.textLabel.text = AudioEffectCellID;
    }else if (tableView==self.recordFilesTableView){
        cell = [self.recordFilesTableView dequeueReusableCellWithIdentifier:AudioEffectCellID forIndexPath:indexPath];
        ((AudioEffectTableViewCell *)cell).titleLabel.text = [self.recordFilesURLArray[indexPath.row].lastPathComponent stringByDeletingPathExtension];
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.soundFontTableView) {
//        [[MidiAudioManager sharedManager] loadFromDLSOrSoundFont:self.soundFontURLArray[indexPath.row] withPatch:0];
        [[AudioEngine sharedEngine] unitSampler:[AudioEngine sharedEngine].instrumentsNode loadSoundBankInstrumentAtURL:self.soundFontURLArray[indexPath.row]];
        self.soundFontTableView.hidden = YES;
    }else if (tableView == self.audioEffectTableView){
        BOOL isPlaying = [self.audioEffectTableViewData[indexPath] boolValue];
        self.audioEffectTableViewData[indexPath] = [NSNumber numberWithBool:!isPlaying];
        AudioEffectTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setIsPlaying:!isPlaying];
        [[AudioEngine sharedEngine] playOrStopAudioPlayerByURL:self.audioEffectURLArray[indexPath.row]];
    }else if (tableView == self.recordFilesTableView){
        BOOL isPlaying = [self.recordFilesTableViewData[indexPath] boolValue];
        self.recordFilesTableViewData[indexPath] = [NSNumber numberWithBool:!isPlaying];
        AudioEffectTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setIsPlaying:!isPlaying];
        [[AudioEngine sharedEngine] startOrStopPlayingRecordAtURL:self.recordFilesURLArray[indexPath.row] withCompletion:^{
            [cell setIsPlaying:NO];
            self.recordFilesTableViewData[indexPath] = [NSNumber numberWithBool:NO];
        }];
    }
}


#pragma mark Velocity

- (IBAction)adjustVelocity:(id)sender{
    UIButton *btn = (UIButton *)sender;
    if (btn.tag==0 && self.velocity>0) {
        self.velocity -=10;
    }else if(self.velocity<100)
        self.velocity +=10;
    self.velocityLabel.text = [NSString stringWithFormat:@"%d",self.velocity];
    if (self.lastKey) {
        [[AudioEngine sharedEngine].instrumentsNode startNote:self.lastKey.tag withVelocity:self.velocity onChannel:2];
    }
    
}
- (IBAction)startOrStopRecording:(id)sender {
    UIButton *btn = (UIButton *)sender;
    if ([AudioEngine sharedEngine].isRecording) {
        [btn setTitle:@"录音" forState:UIControlStateNormal];
        [[AudioEngine sharedEngine] stopRecording];
    }else{
        [[AudioEngine sharedEngine]startRecording];
        [btn setTitle:@"停止" forState:UIControlStateNormal];
    }
}
- (IBAction)playRecord:(id)sender {
    NSError *error;
    NSURL *fileFolderURL = [NSURL URLWithString:NSTemporaryDirectory()];
    self.recordFilesURLArray = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:fileFolderURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    
    if ((nil != self.recordFilesURLArray) && ([self.recordFilesURLArray count] > 0)){
        NSArray * sortedFileList = [self.recordFilesURLArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSDate * mDate1 = nil;
            NSDate * mDate2 = nil;
            if ([(NSURL*)obj1 getResourceValue:&mDate1 forKey:NSURLCreationDateKey error:nil] &&
                [(NSURL*)obj2 getResourceValue:&mDate2 forKey:NSURLCreationDateKey error:nil]) {
                if ([mDate1 timeIntervalSince1970] < [mDate2 timeIntervalSince1970]) {
                    return (NSComparisonResult)NSOrderedDescending;
                }else{
                    return (NSComparisonResult)NSOrderedAscending;
                }
            }
            return (NSComparisonResult)NSOrderedSame; // there was an error in getting the value
        }];
        self.recordFilesURLArray = sortedFileList;
    }
    
    [self.recordFilesTableView reloadData];
    self.recordFilesTableView.hidden = !self.recordFilesTableView.hidden;
}

- (void)initMIDIClient{
    OSStatus err;
    NSString *clientName = @"inputClient";
    err = MIDIClientCreate((CFStringRef)CFBridgingRetain(clientName), pianoMIDINotifyProc, NULL, &_MIDIClientRef);
    if (err != noErr) {
        NSLog(@"MIDIClientCreate err = %d", err);
        return ;
    }
    
    NSString *inputPortName = @"inputPort";
    err = MIDIInputPortCreate(
                              _MIDIClientRef, (CFStringRef)CFBridgingRetain(inputPortName),
                              pianoMIDIInputProc, NULL, &_MIDIInputPortRef);
    if (err != noErr) {
        NSLog(@"MIDIInputPortCreate err = %d", err);
        return ;
    }
}

static void pianoMIDIInputProc(const MIDIPacketList *pktlist,
              void *readProcRefCon, void *srcConnRefCon)
{
    MIDIPacket *packet = (MIDIPacket *)&(pktlist->packet[0]);
    UInt32 packetCount = pktlist->numPackets;
    
    for (NSInteger i = 0; i < packetCount; i++) {
        
        Byte mes = packet->data[0] & 0xF0;
        Byte ch = packet->data[0] & 0x0F;
        
        if ((mes == 0x90) && (packet->data[2] != 0)) {
            NSLog(@"note on number = %2.2x / velocity = %2.2x / channel = %2.2x",
                  packet->data[1], packet->data[2], ch);
            [[AudioEngine sharedEngine].instrumentsNode startNote:packet->data[1] withVelocity:packet->data[2] onChannel:2];
        } else if (mes == 0x80 || mes == 0x90) {
            [[AudioEngine sharedEngine].instrumentsNode stopNote:packet->data[1] onChannel:2];
            NSLog(@"note off number = %2.2x / velocity = %2.2x / channel = %2.2x",
                  packet->data[1], packet->data[2], ch);
        } else if (mes == 0xB0) {
            NSLog(@"cc number = %2.2x / data = %2.2x / channel = %2.2x",
                  packet->data[1], packet->data[2], ch);
        } else {
            NSLog(@"etc");
        }
        
        packet = MIDIPacketNext(packet);
    }
}

static void pianoMIDINotifyProc(const MIDINotification *message, void *refCon)
{
    OSStatus err;
    switch (message->messageID)
    {
        case kMIDIMsgObjectAdded:{
            ItemCount sourceCount = MIDIGetNumberOfSources();
            
            NSLog( @"errsourceCount = %lu", sourceCount );
            for (ItemCount i = 0; i < sourceCount; i++) {
                MIDIEndpointRef sourcePointRef = MIDIGetSource(i);
                err = MIDIPortConnectSource(_MIDIInputPortRef, sourcePointRef, NULL);
                if (err != noErr) {
                    NSLog(@"MIDIPortConnectSource err = %d", err);
                    return ;
                }
            }
        }
            break;
        case kMIDIMsgObjectRemoved:
            break;
        case kMIDIMsgSetupChanged:
            break;
        case kMIDIMsgPropertyChanged:
            break;
        case kMIDIMsgThruConnectionsChanged:
            break;
        case kMIDIMsgSerialPortOwnerChanged:
            break;
        case kMIDIMsgIOError:
            break;
    }
}


#pragma AudioEffectTableViewCell delegate

- (void)cell:(UITableViewCell *)cell volumeChangeToValue:(float)value{
    NSIndexPath *indexPath = [self.audioEffectTableView indexPathForCell:cell];
    [[AudioEngine sharedEngine] adjustAudioPlayerVolume:value byURL:self.audioEffectURLArray[indexPath.row]];
}


- (void)pianoKey:(PianoKey *)pianoKey touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
}
- (void)pianoKey:(PianoKey *)pianoKey touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
}
- (void)pianoKey:(PianoKey *)pianoKey touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}
@end
