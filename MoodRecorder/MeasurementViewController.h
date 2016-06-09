//
//  MeasurementViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/19.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MeasurementViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *lblClear;
@property (weak, nonatomic) IBOutlet UILabel *lblObscure;
@property (weak, nonatomic) IBOutlet UILabel *lblCountDown;
@property (weak, nonatomic) IBOutlet UIImageView *drawImageView;

@end
