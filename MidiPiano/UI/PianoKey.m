//
//  PianoKey.m
//  MidiPiano
//
//  Created by Tab on 29/10/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "PianoKey.h"

@implementation PianoKey

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    return [self superview];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(self.frame, point);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    if (_delegate) {
        [_delegate pianoKey:self touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    if (_delegate) {
        [_delegate pianoKey:self touchesMoved:touches withEvent:event];
    }
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    if (_delegate) {
        [_delegate pianoKey:self touchesEnded:touches withEvent:event];
    }
    
}

@end
