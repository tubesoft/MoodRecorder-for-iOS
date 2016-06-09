//
//  ViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/18.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
- (IBAction)touchStart:(id)sender;
- (IBAction)touchCombMeasurement:(id)sender;
- (IBAction)touchPulseWave:(id)sender;


@end

