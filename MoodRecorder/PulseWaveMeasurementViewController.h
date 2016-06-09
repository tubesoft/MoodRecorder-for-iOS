//
//  PulseWaveMeasurementViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/20.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PulseWaveMeasurementViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *lblLevel;
@property (weak, nonatomic) IBOutlet UIButton *btnStartStop;
- (IBAction)btnStartStop:(id)sender;

@end
