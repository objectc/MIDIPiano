//
//  AudioEffectTableViewCell.h
//  MidiPiano
//
//  Created by Tab on 16/11/2016.
//  Copyright © 2016 Tab. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol AudioEffectTableViewCellDelegate <NSObject>

- (void)cell:(UITableViewCell*)cell volumeChangeToValue:(float)value;

@end

@interface AudioEffectTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic,weak)IBOutlet id<AudioEffectTableViewCellDelegate>delegate;
@property(nonatomic,assign)bool isPlaying;
@end
