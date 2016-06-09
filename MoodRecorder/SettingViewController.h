//
//  SettingViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/19.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerSampRate;
@property (weak, nonatomic) IBOutlet UISwitch *switchTracking;
- (IBAction)actionSwitch:(id)sender;

@end
