//
//  Result2ViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/21.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "Result2ViewController.h"
#import "BEMSimpleLineGraphView.h"


@interface Result2ViewController ()
@property NSArray* pulseValues;
@property NSArray* times;
@property NSArray* paths;
@property NSString* docDir;
@property NSString *filePath;
@property NSDateFormatter *formatter;
@property BEMSimpleLineGraphView *graphView;
@property int counter;
@property int cntSec;
@property int sampRate;
@property float interval;
@end

@implementation Result2ViewController
@synthesize scrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    //エッジスワイプで戻るのを無効
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    //保存ファイルの読み出し
    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    self.filePath = [NSString stringWithFormat:@"%@/tempData.dat", self.docDir];
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithFile:self.filePath];
    self.times = [dict objectForKey:@"Time"];
    self.pulseValues = [dict objectForKey:@"PulseWave"];
    self.sampRate = [[[dict objectForKey:@"SamplingRate"] objectAtIndex:0] intValue];
    
    self.counter = 0;
    self.cntSec = 0;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss.SSS"];
    
    NSDate *beginTime = [self.times objectAtIndex:0];
    NSDate *endTime = [self.times objectAtIndex:[self.times count]-1];
    self.interval = [endTime timeIntervalSinceDate:beginTime];

    //スクロールビューの設定
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake(200*self.interval, 455);
    scrollView.pagingEnabled = NO;
    scrollView.minimumZoomScale = 0.1f;
    scrollView.maximumZoomScale = 2.0f;
    //グラフビューの設定
    self.graphView =
    [[BEMSimpleLineGraphView alloc]
     initWithFrame:CGRectMake(0, 0, 200*self.interval, 455)];
    
    self.graphView.dataSource = self;
    self.graphView.delegate = self;
//    self.graphView.enableReferenceAxisFrame = YES;
//    self.graphView.enableReferenceXAxisLines = YES;
//    self.graphView.enableReferenceYAxisLines = YES;
//    self.graphView.enableXAxisLabel = YES;
//    self.graphView.enableYAxisLabel = YES;
//    self.graphView.enableBezierCurve = YES;
//    self.graphView.autoScaleYAxis = YES;
//    self.graphView.enablePopUpReport = YES;
//    self.graphView.colorTop = [UIColor blueColor];
//    self.graphView.colorBottom = [UIColor blueColor];
    
    [scrollView addSubview:self.graphView];

}
- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return [self.pulseValues count]; // Number of points in the graph.
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    return [[self.pulseValues objectAtIndex:index] floatValue]; // The value of the point on the Y-Axis for the index.
}

//- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index {
//    if (self.counter == self.sampRate) {
//        self.cntSec++;
//        self.counter = 0;
//    }
//    self.counter++;
//    NSString *cntSecStr = [NSString stringWithFormat:@"%d", self.cntSec];
//    return[cntSecStr stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
//}


// ズームを画像に適用する
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.graphView;
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
