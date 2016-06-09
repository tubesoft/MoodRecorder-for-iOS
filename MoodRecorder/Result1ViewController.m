//
//  Result1ViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/20.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "Result1ViewController.h"
#import "DrawResultPlotView.h"

@interface Result1ViewController ()
@property NSString *dateStr;
@property NSString *samplingRateStr;
@property NSString *isTrackedStr;

@end

@implementation Result1ViewController
@synthesize lblDate;
@synthesize lblTracking;
@synthesize lblSamplingRate;
@synthesize imageView;
DrawResultPlotView *drawView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //エッジスワイプで戻るのを無効
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/tempData.dat", docDir];
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    NSDate *date = [[dict objectForKey:@"MeasurementDate"] objectAtIndex:0];
    self.dateStr = [NSString stringWithFormat:@"%@\n",[formatter1 stringFromDate:date]];
    self.samplingRateStr = [NSString stringWithFormat:@"%@ Hz",[[dict objectForKey:@"SamplingRate"] objectAtIndex:0]];
    if ([[[dict valueForKey:@"IsTracked"] objectAtIndex:0] isEqual:@"TRUE"]){
        self.isTrackedStr = @"/w tr";
    } else {
        self.isTrackedStr = @"w/o tr";
    }
    lblDate.text = self.dateStr;
    lblSamplingRate.text = self.samplingRateStr;
    lblTracking.text = self.isTrackedStr;
    
    NSArray *array = [dict objectForKey:@"Coodinate"];
    [self addNewPoint];
    [drawView setLocations:array];
    [drawView setNeedsDisplay];
    
}

- (void) addNewPoint {
    drawView = [[DrawResultPlotView alloc] init];
    drawView.frame = CGRectMake(0, 0, 320, 320);
    drawView.center = CGPointMake(160, 160);
    // opaque属性にNOを設定する事で、背景透過を許可する
    drawView.opaque = NO;
    // backgroundColorにalpha=0.0fの背景色を設定することで、背景色を透明にしている
    drawView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    // 作成した背景色透明のViewを現在のViewの上に追加する
    [imageView addSubview:drawView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
