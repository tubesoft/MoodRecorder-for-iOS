//
//  MeasurementViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/19.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "MeasurementViewController.h"

@interface MeasurementViewController ()
@property NSTimer* countDownTimer;
@property NSTimer* measurementTimer;
@property NSArray *dataKeys;
@property NSMutableArray *valuesTime;
@property NSMutableArray *valuesCoodinate;
@property NSDictionary *recordDict;
@property NSMutableArray *dataArray;
@property UIAlertController *ac;
@property int countDownNum;
@property int measurementMin;
@property int measurementSec;
@property int measurementSecSum;
@property int count;
@property int countSecs;
@property int samplingRate;
@property Boolean isTracked;
@property NSNumber *xValue;
@property NSNumber *yValue;

@property NSArray* paths;
@property NSString* docDir;
@property UIImage* lastDrawImage;
@property CGPoint coodinate;
@property UIBezierPath *bezierPath;

@end

@implementation MeasurementViewController
@synthesize drawImageView;
@synthesize lblClear;
@synthesize lblObscure;
@synthesize lblCountDown;

- (void)viewDidLoad {
    [super viewDidLoad];
    //変数の初期化
    self.countDownNum = 3;
    [lblObscure setTransform:CGAffineTransformMakeRotation(3*M_PI/2)];
    [lblClear setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [lblCountDown setText:[NSString stringWithFormat:@"%d",self.countDownNum]];
    self.dataArray = [NSMutableArray array];
    
    [self createAlert];
    
    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    
    NSString *filePath = [NSString stringWithFormat:@"%@/pickerValues.dat", self.docDir];
    NSArray *pickerValues = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    self.measurementMin = [[pickerValues objectAtIndex:0] intValue];
    self.measurementSec = [[pickerValues objectAtIndex:1] intValue];
    self.measurementSecSum = self.measurementMin*60 + self.measurementSec;
    self.xValue = 0;
    self.yValue = 0;
    self.countSecs = 0;
    self.count = 0;
    self.valuesTime = [NSMutableArray array];
    self.valuesCoodinate = [NSMutableArray array];
    
    NSString *settingPath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    NSArray *setting = [NSKeyedUnarchiver unarchiveObjectWithFile:settingPath];
    self.samplingRate = [[setting objectAtIndex:0] intValue];
    self.isTracked = [[setting objectAtIndex:1] boolValue];
    
    NSLog(@"計測時間：%d秒",self.measurementSecSum);

    self.dataArray = [NSMutableArray array];
    self.dataKeys = [NSArray arrayWithObjects:
                    @"Time",
                    @"Coodinate",
                    nil];
    self.countDownTimer = [NSTimer
                           scheduledTimerWithTimeInterval:1
                           target:self
                           selector:@selector(countDownSchedule)
                           userInfo:nil
                           repeats:YES];
}

//タッチ時処理
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    [self locatingTouch:touch];
    if (self.isTracked) {
        self.bezierPath = [UIBezierPath bezierPath];
        self.bezierPath.lineCapStyle = kCGLineCapRound;
        self.bezierPath.lineWidth = 4.0;
        [self.bezierPath moveToPoint:self.coodinate];
    }
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    [self locatingTouch:touch];
    if (self.isTracked) {
        [self.bezierPath addLineToPoint:self.coodinate];
        [self drawLine:self.bezierPath];
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    [self locatingTouch:touch];
    if (self.isTracked) {
        [self.bezierPath addLineToPoint:self.coodinate];
        [self drawLine:self.bezierPath];
        self.lastDrawImage = self.drawImageView.image;
    }
}

-(void)locatingTouch:(UITouch*)touch{
    self.coodinate = [touch locationInView:drawImageView];
    NSLog(@"x座標:%f y座標:%f",self.coodinate.x,self.coodinate.y);
    self.xValue = [NSNumber numberWithFloat:self.coodinate.x];
    self.yValue = [NSNumber numberWithFloat:self.coodinate.y];
}


//最初のカウントダウン時の処理
-(void)countDownSchedule{
    if (self.countDownNum>1) {
        self.countDownNum--;
        [lblCountDown setText:[NSString stringWithFormat:@"%d",self.countDownNum]];
        
    } else {
        [lblCountDown setHidden:YES];
        float interval = 1.0f/(float)self.samplingRate;
        self.measurementTimer = [NSTimer
                                 scheduledTimerWithTimeInterval:interval
                                 target:self
                                 selector:@selector(measurementSchedule)
                                 userInfo:nil
                                 repeats:YES];
        NSLog(@"サンプリングレート：%d Hz",self.samplingRate);
        NSLog(@"インターバル：%f",interval);
        [self.countDownTimer invalidate];
    }
}

//測定中の処理
-(void)measurementSchedule{
    if(self.count==self.samplingRate){
        self.count = 0;
        self.countSecs++;
        NSLog(@"%d 秒経過",self.countSecs);
    }
    if(self.measurementSecSum>self.countSecs){
        [self.valuesTime addObject:[NSDate date]];
        [self.valuesCoodinate addObject:[NSValue valueWithCGPoint:self.coodinate]];
    } else {
        // アラート表示処理
        [self.measurementTimer invalidate];
        [self presentViewController:self.ac animated:YES completion:nil];
    }
    self.count++;
}

-(void)saveData{
    NSString *filePath = [NSString stringWithFormat:@"%@/records.dat", self.docDir];

    NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    if ([array count] == 0) {
        array = [NSMutableArray array];
    }
    
    NSArray *dateSingleArray = [NSArray arrayWithObject:[NSDate date]];
    NSArray *samplSingleArray = [NSArray arrayWithObject:@(self.samplingRate)];
    NSArray *isTrackedSingleArray;
    if (self.isTracked) {
        isTrackedSingleArray = [NSArray arrayWithObject:@"TRUE"];
    } else {
        isTrackedSingleArray = [NSArray arrayWithObject:@"FALSE"];
    }
    
    NSArray *keys = [NSArray arrayWithObjects:
                     @"MeasurementDate",
                     @"SamplingRate",
                     @"IsTracked",
                     @"Time",
                     @"Coodinate",
                     nil];
    
    NSArray *values = [NSArray arrayWithObjects:
                       dateSingleArray,
                       samplSingleArray,
                       isTrackedSingleArray,
                       self.valuesTime,
                       self.valuesCoodinate,
                       nil];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [array addObject:dict];
    
    BOOL successful = [NSKeyedArchiver archiveRootObject:array toFile:filePath];
    if (successful) {
        NSLog(@"%@", @"新規データの保存に成功しました。");
    }
    
    [self saveDataAsTxt:array];
    [self saveTempData:dict];
}

-(void)saveDataAsTxt:(NSMutableArray*)array{
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    [formatter2 setDateFormat:@"HH:mm:ss.SSS"];
    NSMutableData *data = [NSMutableData data];
    NSData *dataLine;
    NSString *filePath = [NSString stringWithFormat:@"%@/records.txt", self.docDir];
    CGFloat imageViewWidth = self.drawImageView.frame.size.width;
    
    
    //記録単位のリスト
    for (int i=0; i<[array count]; i++) {
        NSDictionary *dict = [array objectAtIndex:i];
        
        NSDate *date = [[dict objectForKey:@"MeasurementDate"] objectAtIndex:0];
        dataLine = [[NSString stringWithFormat:@"%@,,\n",[formatter1 stringFromDate:date]] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        NSString *sampRate = [[dict objectForKey:@"SamplingRate"] objectAtIndex:0];
        dataLine = [[NSString stringWithFormat:@"%@,,\n",sampRate] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        NSString *isTrackedStr = [[dict objectForKey:@"IsTracked"] objectAtIndex:0];
        dataLine = [[NSString stringWithFormat:@"%@,,\n",isTrackedStr] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        //測定値一行単位のリスト
        NSArray *timeArray = [dict objectForKey:@"Time"];
        NSArray *coodinateArray = [dict objectForKey:@"Coodinate"];
        for (int j=0; j<[timeArray count]; j++) {
            //測定値のタイムスタンプ,X,Y
            NSDate *timeStep = [timeArray objectAtIndex:j];
            NSString *timeStepStr = [formatter2 stringFromDate:timeStep];
            NSValue *coodinateVal = [coodinateArray objectAtIndex:j];
            CGPoint coodinate = [coodinateVal CGPointValue];
            CGFloat xVal = (coodinate.x*2-imageViewWidth)/imageViewWidth;
            CGFloat yVal = (coodinate.y*2-imageViewWidth)/imageViewWidth;
            NSString *stepStr = [NSString stringWithFormat:@"%@,%f,%f\n",timeStepStr,xVal,yVal];
            dataLine = [stepStr dataUsingEncoding:NSUTF8StringEncoding];
            [data appendData:dataLine];
        }
        dataLine = [@"EOR,,\n" dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
    }
    BOOL successful = [data writeToFile:filePath atomically:YES];
    if (successful) {
        NSLog(@"%@", @"TXTファイルの保存に成功しました。");
    }
}

-(void)saveTempData:(NSDictionary*)dict{
    NSString *filePath = [NSString stringWithFormat:@"%@/tempData.dat", self.docDir];
    BOOL successful = [NSKeyedArchiver archiveRootObject:dict toFile:filePath];
    if (successful) {
        NSLog(@"%@", @"一時データの保存に成功しました。");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)createAlert{
    // コントローラを生成
    self.ac =
    [UIAlertController alertControllerWithTitle:@"Massage"
                                        message:@"Do you want to save the data?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {
                               // ボタンタップ時の処理
                               [self.measurementTimer invalidate];
                               [self saveData];
                               // 結果画面に移る
                               [self performSegueWithIdentifier:@"FromMeasurementToResult" sender:self];
                               
                           }];
    UIAlertAction * discardAction =
    [UIAlertAction actionWithTitle:@"Discard"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {
                               // ボタンタップ時の処理
                               [self.measurementTimer invalidate];
                               // トップ画面に移る
                               [self performSegueWithIdentifier:@"FromMeasurementToTop" sender:self];
                               
                           }];
    // コントローラにアクションを追加
    [self.ac addAction:okAction];
    [self.ac addAction:discardAction];
}

- (void)drawLine:(UIBezierPath*)path {
    // 非表示の描画領域を生成します。
    UIGraphicsBeginImageContext(self.drawImageView.frame.size);
    // 描画領域に、前回までに描画した画像を、描画します。
    [self.lastDrawImage drawAtPoint:CGPointZero];
    // 色をセットします。
//    [[UIColor blueColor] setStroke];
    [[UIColor colorWithRed:0.0 green:0.0 blue:2.0 alpha:0.7] setStroke];
    // 線を引きます。
    [path stroke];
    // 描画した画像をcanvasにセットして、画面に表示します。
    self.drawImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    // 描画を終了します。
    UIGraphicsEndImageContext();
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
