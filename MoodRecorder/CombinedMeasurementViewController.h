//
//  CombinedMeasurementViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/21.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CombinedMeasurementViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblClear;
@property (weak, nonatomic) IBOutlet UILabel *lblObscure;
@property (weak, nonatomic) IBOutlet UILabel *lblCountDown;

@property (weak, nonatomic) IBOutlet UIProgressView *gauge;
@property (weak, nonatomic) IBOutlet UILabel *lblInstruction;
@property (weak, nonatomic) IBOutlet UIImageView *drawImageView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
- (IBAction)pressStart:(id)sender;


@end
