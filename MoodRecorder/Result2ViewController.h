//
//  Result2ViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/21.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMSimpleLineGraphView.h"

@interface Result2ViewController : UIViewController<BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
