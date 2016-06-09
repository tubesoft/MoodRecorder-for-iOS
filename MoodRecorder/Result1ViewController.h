//
//  Result1ViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/20.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Result1ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblSamplingRate;
@property (weak, nonatomic) IBOutlet UILabel *lblTracking;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
