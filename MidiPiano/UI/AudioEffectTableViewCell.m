//
//  AudioEffectTableViewCell.m
//  MidiPiano
//
//  Created by Tab on 16/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import "AudioEffectTableViewCell.h"

@implementation AudioEffectTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
//    if (selected)
//        self.accessoryType = UITableViewCellAccessoryCheckmark;
//    else
//        self.accessoryType = UITableViewCellAccessoryNone;
    // Configure the view for the selected state
}

- (IBAction)volumeChanged:(id)sender {
    UISlider *volumeSlider = (UISlider *)sender;
    if ([self.delegate respondsToSelector:@selector(cell:volumeChangeToValue:)]) {
        [self.delegate cell:self volumeChangeToValue:volumeSlider.value];
    }
}

- (void)setIsPlaying:(bool)isPlaying{
    _isPlaying = isPlaying;
    self.accessoryType = isPlaying? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
}


@end
