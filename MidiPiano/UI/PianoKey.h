//
//  PianoKey.h
//  MidiPiano
//
//  Created by Tab on 29/10/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PianoKey;
@protocol PianoKeyDelegate <NSObject>
- (void) pianoKey:(PianoKey*)pianoKey touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void) pianoKey:(PianoKey*)pianoKey touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void) pianoKey:(PianoKey*)pianoKey touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;

@end

@interface PianoKey : UIButton

@property (nonatomic, weak) id<PianoKeyDelegate> delegate;

@end
