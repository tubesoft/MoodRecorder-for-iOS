//
//  CombinedMeasurementViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/21.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "CombinedMeasurementViewController.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CombinedMeasurementViewController ()
//タッチ関係
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
//カメラ関係
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property int fps;
@property Boolean isStarted;
@property NSMutableArray* pulseWaveRecords;

@property int countCheck;
@property Boolean isReady;
@property CGFloat maxValue;
@property CGFloat minValue;
@property CGFloat distMaxMin;
@property CGFloat adjustVal;

@end

@implementation CombinedMeasurementViewController
@synthesize drawImageView;
@synthesize lblClear;
@synthesize lblObscure;
@synthesize lblCountDown;
@synthesize btnStart;
@synthesize lblInstruction;
@synthesize gauge;

- (void)viewDidLoad {
    [super viewDidLoad];
    //変数の初期化
    self.countDownNum = 3;
    [lblObscure setTransform:CGAffineTransformMakeRotation(3*M_PI/2)];
    [lblClear setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [lblCountDown setHidden:YES];
    [lblCountDown setText:[NSString stringWithFormat:@"%d",self.countDownNum]];
    
    self.dataArray = [NSMutableArray array];
    
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
    self.dataArray = [NSMutableArray array];
    
    self.dataKeys = [NSArray arrayWithObjects:
                     @"Time",
                     @"Coodinate",
                     nil];

    NSLog(@"計測時間：%d秒",self.measurementSecSum);
    NSLog(@"サンプリングレート：%d Hz",self.samplingRate);
    //カメラ関係のセットアップ
    self.isStarted = false;
    self.fps = self.samplingRate;
    self.pulseWaveRecords = [NSMutableArray array];
    [self setupAVCapture];
    
    self.isReady = false;
    self.countCheck = 3*self.fps+1;
    self.maxValue = 0;
    self.minValue = 1;
    self.distMaxMin = 10;
    self.adjustVal = 0.75;
    [self.gauge setProgressTintColor:[UIColor redColor]];
}


- (IBAction)pressStart:(id)sender {
    [lblCountDown setHidden:NO];
    self.countDownTimer = [NSTimer
                           scheduledTimerWithTimeInterval:1
                           target:self
                           selector:@selector(countDownSchedule)
                           userInfo:nil
                           repeats:YES];
    [btnStart setHidden:YES];
    [lblInstruction setHidden:YES];
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
//    NSLog(@"x座標:%f y座標:%f",self.coodinate.x,self.coodinate.y);
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
        [self.countDownTimer invalidate];
        self.isStarted = true;
    }
}

//測定中の処理
-(void)measurementSchedule:(CGFloat)redLevel{
    if(self.count==self.samplingRate){
        self.count = 0;
        self.countSecs++;
        NSLog(@"%d 秒経過",self.countSecs);
    }
    if(self.measurementSecSum>self.countSecs){
        [self.valuesTime addObject:[NSDate date]];
        [self.valuesCoodinate addObject:[NSValue valueWithCGPoint:self.coodinate]];
        [self.pulseWaveRecords addObject:@(redLevel)];
    } else {
        //計測処理を終了
//        [self.session stopRunning];
        [self tearDownAVCapture];
        // アラート表示処理
        [self createAlert];
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
                     @"PulseWave",
                     nil];
    
    NSArray *values = [NSArray arrayWithObjects:
                       dateSingleArray,
                       samplSingleArray,
                       isTrackedSingleArray,
                       self.valuesTime,
                       self.valuesCoodinate,
                       self.pulseWaveRecords,
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
        dataLine = [[NSString stringWithFormat:@"%@,,,\n",[formatter1 stringFromDate:date]] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        NSString *sampRate = [[dict objectForKey:@"SamplingRate"] objectAtIndex:0];
        dataLine = [[NSString stringWithFormat:@"%@,,,\n",sampRate] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        NSString *isTrackedStr = [[dict objectForKey:@"IsTracked"] objectAtIndex:0];
        dataLine = [[NSString stringWithFormat:@"%@,,,\n",isTrackedStr] dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
        
        //測定値一行単位のリスト
        NSArray *timeArray = [dict objectForKey:@"Time"];
        NSArray *coodinateArray = [dict objectForKey:@"Coodinate"];
        NSArray *pulseArray = [dict objectForKey:@"PulseWave"];
        for (int j=0; j<[timeArray count]; j++) {
            //測定値のタイムスタンプ,X,Y
            NSDate *timeStep = [timeArray objectAtIndex:j];
            NSString *timeStepStr = [formatter2 stringFromDate:timeStep];
            NSValue *coodinateVal = [coodinateArray objectAtIndex:j];
            CGPoint coodinate = [coodinateVal CGPointValue];
            CGFloat xVal = (coodinate.x*2-imageViewWidth)/imageViewWidth;
            CGFloat yVal = (coodinate.y*2-imageViewWidth)/imageViewWidth;
            NSString *pulse = [pulseArray objectAtIndex:j];
            NSString *stepStr = [NSString stringWithFormat:@"%@,%f,%f,%@\n",timeStepStr,xVal,yVal,pulse];
            dataLine = [stepStr dataUsingEncoding:NSUTF8StringEncoding];
            [data appendData:dataLine];
        }
        dataLine = [@"EOR,,,\n" dataUsingEncoding:NSUTF8StringEncoding];
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
                               [self performSegueWithIdentifier:@"FromCombMeasurementToResult" sender:self];
                               
                           }];
    UIAlertAction * discardAction =
    [UIAlertAction actionWithTitle:@"Discard"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {
                               // ボタンタップ時の処理
                               [self.measurementTimer invalidate];
                               // トップ画面に移る
                               [self performSegueWithIdentifier:@"FromCombMeasurementToTop" sender:self];
                               
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
 カメラ関係の処理群
 */
- (void)setupAVCapture
{
    NSError *error = nil;
    
    // 入力と出力からキャプチャーセッションを作成
    self.session = [[AVCaptureSession alloc] init];
    
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // カメラからの入力を作成
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // カメラからの入力を作成し、セッションに追加
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    [self.session addInput:self.videoInput];
    
    // 画像への出力を作成し、セッションに追加
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.session addOutput:self.videoDataOutput];
    
    // ビデオ出力のキャプチャの画像情報のキューを設定
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:TRUE];
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    
    // ビデオへの出力の画像は、BGRAで出力
    self.videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [camera formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= self.fps && self.fps <= range.maxFrameRate && width >= maxWidth) {
                
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    
    [camera lockForConfiguration:nil];
    //露出の設定をつけてみた
    [camera setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:100 completionHandler:nil];
//    camera.exposureMode = AVCaptureExposureModeCustom;
//    camera.focusMode = AVCaptureFocusModeLocked;
//    camera.whiteBalanceMode= AVCaptureWhiteBalanceModeLocked;
    
    camera.torchMode=AVCaptureTorchModeOn;
    camera.activeFormat = selectedFormat;
    camera.activeVideoMinFrameDuration = CMTimeMake(1, self.fps);
    camera.activeVideoMaxFrameDuration = CMTimeMake(1, self.fps);
    [camera unlockForConfiguration];
    
    [self.session startRunning];
}

// AVCaptureVideoDataOutputSampleBufferDelegateプロトコルのメソッド。新しいキャプチャの情報が追加されたときに呼び出される。
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // キャプチャしたフレームからCGImageを作成
//    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    //脈波のレベル
    static int count=0;
    count++;
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    NSInteger width = CVPixelBufferGetWidth(cvimgRef);
    NSInteger height = CVPixelBufferGetHeight(cvimgRef);
    
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    float r=0,g=0,b=0;
    
    long widthScaleFactor = width/192;
    long heightScaleFactor = height/144;
    
    for(int y=0; y < height; y+=heightScaleFactor) {
        for(int x=0; x < width*4; x+=(4*widthScaleFactor)) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
        }
        buf+=bprow;
    }
    
    r/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    g/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    b/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    
    //    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    float hue, sat, bright;
    RGBtoHSVComb(r, g, b, &hue, &sat, &bright);
    //    [color getHue:&hue saturation:&sat brightness:&bright alpha:nil];
    
    
    // 画像の結果を反映
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isStarted) {
            [self measurementSchedule:1-r];
        } else {
            [self adjustGauge:r];
        }
        [gauge setProgress:(r-self.adjustVal)/self.distMaxMin-0.25f];
    });
}

-(void)adjustGauge:(CGFloat)redValue{
    if (redValue>self.maxValue){
        self.maxValue = redValue;
    }
    if (redValue<self.minValue) {
        self.minValue = redValue;
    }
    if (self.countCheck > self.fps){
        if ((self.minValue-self.adjustVal)/self.distMaxMin-0.25f<0.1
        ||(self.maxValue-self.adjustVal)/self.distMaxMin-0.25f>0.9){
            self.adjustVal = self.minValue-0.05;
            self.distMaxMin = (self.maxValue-self.adjustVal);
            self.minValue = 1;
            self.maxValue = 0;
            [self.gauge setProgressTintColor:[UIColor redColor]];
        } else {
            if (!self.isReady) {
                self.adjustVal = self.minValue-0.05;
                self.distMaxMin = (self.maxValue-self.adjustVal);
                self.isReady = true;
            }
            [self.gauge setProgressTintColor:nil];
            self.minValue = 1;
            self.maxValue = 0;
        }
        self.countCheck = 0;
    }
    if ((self.minValue-self.adjustVal)/self.distMaxMin-0.25f<0.1
        ||(self.maxValue-self.adjustVal)/self.distMaxMin-0.25f>0.9){
        [self.gauge setProgressTintColor:[UIColor redColor]];
        self.isReady = false;
    }
    self.countCheck++;
}

// サンプルバッファのデータからCGImageRefを生成する
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // ピクセルバッファのベースアドレスをロックする
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get information of the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // RGBの色空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    
    CGImageRelease(cgImage);
    
    return image;
}


void RGBtoHSVComb( float r, float g, float b, float *h, float *s, float *v ) {
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h=2+(b-r)/delta;
    else
        *h=4+(r-g)/delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
}

- (void)tearDownAVCapture
{
    [self.session stopRunning];
    for (AVCaptureOutput *output in self.session.outputs) {
        [self.session removeOutput:output];
    }
    for (AVCaptureInput *input in self.session.inputs) {
        [self.session removeInput:input];
    }
    self.videoDataOutput = nil;
    self.videoInput = nil;
    self.session = nil;
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
