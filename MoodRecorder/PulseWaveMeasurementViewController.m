//
//  PulseWaveMeasurementViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/20.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "PulseWaveMeasurementViewController.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

@interface PulseWaveMeasurementViewController ()
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property int fps;
@property Boolean isOn;
@property NSMutableArray* list;
@property NSArray* paths;
@property NSString* docDir;
@property int count;
@property int okCounter;
@property CGFloat maxValue;
@property CGFloat minValue;
@property CGFloat currentMin;
@property CGFloat currentMax;
@end

@implementation PulseWaveMeasurementViewController

@synthesize imageView;
@synthesize slider;
@synthesize lblLevel;
@synthesize btnStartStop;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isOn = false;
    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    NSArray *settingArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    NSString *sampRateStr = [settingArray objectAtIndex:0];
    int sampRate = [sampRateStr intValue];
    self.fps = sampRate;
    
    self.count = 3*self.fps+1;
    self.okCounter = 0;
    self.maxValue = 0;
    self.currentMax = 1;
    self.minValue = 1;
    self.currentMin = 0;
    [self.slider setMinimumTrackTintColor:[UIColor redColor]];
    [self setupAVCapture];
}

- (IBAction)btnStartStop:(id)sender {
    
    if (self.isOn){
        [self.session stopRunning];
        [btnStartStop setTitle:@"Start" forState:UIControlStateNormal];
        self.isOn = false;
        [self writeData];
        // コントローラを生成
        UIAlertController * ac =
        [UIAlertController alertControllerWithTitle:@"Message"
                                            message:@"The file has been saved"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        // OK用のアクションを生成
        UIAlertAction * okAction =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   // ボタンタップ時の処理
                                   NSLog(@"OK button tapped.");
                               }];
        
        // コントローラにアクションを追加
        [ac addAction:okAction];
        
        // アラート表示処理
        [self presentViewController:ac animated:YES completion:nil];
        
        
        // アクションシート表示処理
        //        [self presentViewController:ac animated:YES completion:nil];
        
    } else{
        [btnStartStop setTitle:@"Stop" forState:UIControlStateNormal];
        //記録開始
        self.list = [NSMutableArray array];
        self.isOn = true;
    }
}


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
    
    //    // ビデオ入力のAVCaptureConnectionを取得
    //    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //
    //    // 1秒あたり4回画像をキャプチャ
    //    videoConnection.videoMinFrameDuration = CMTimeMake(1, 4);
//    AVCaptureDeviceFormat *currentFormat;
//    for (AVCaptureDeviceFormat *format in camera.formats)
//    {
//        NSArray *ranges = format.videoSupportedFrameRateRanges;
//        AVFrameRateRange *frameRates = ranges[0];
//        
//        if (frameRates.maxFrameRate == self.fps &&
//            (!currentFormat || (CMVideoFormatDescriptionGetDimensions(format.formatDescription).width < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).width &&
//                    CMVideoFormatDescriptionGetDimensions(format.formatDescription).height < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).height)))
//        {
//            currentFormat = format;
//        }
//    }
    AVCaptureDeviceFormat *currentFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [camera formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= self.fps && self.fps <= range.maxFrameRate && width >= maxWidth) {
                
                currentFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    
    [camera lockForConfiguration:nil];
    //露出の設定をつけてみた
    [camera setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:100 completionHandler:nil];
    //camera.exposureMode = AVCaptureExposureModeCustom;
    //camera.focusMode = AVCaptureFocusModeLocked;
    //camera.whiteBalanceMode= AVCaptureWhiteBalanceModeLocked;
    
    camera.torchMode=AVCaptureTorchModeOn;
    camera.activeFormat = currentFormat;
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
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
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
    
    RGBtoHSV(r, g, b, &hue, &sat, &bright);
    
    //    [color getHue:&hue saturation:&sat brightness:&bright alpha:nil];
    
    
    // 画像を画面に表示
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
        [lblLevel setText:[NSString stringWithFormat:@"%f",r]];
        [slider setValue:r];
        if (self.isOn) {
            [self schedule:r];
        } else {
            [self adjustSlider:r];
        }
    });
}

-(void)schedule:(CGFloat)redValue{
    [self.list addObject:@(1-redValue)];
}

-(void)adjustSlider:(CGFloat)redValue{
    if (redValue>self.maxValue){
        self.maxValue = redValue;
    }
    if (redValue<self.minValue) {
        self.minValue = redValue;
    }
    if (self.count > self.fps){
        if (self.minValue<self.currentMin
            || self.maxValue>self.currentMax
            || self.maxValue-self.minValue<(self.currentMax-self.currentMin)/4
            || self.maxValue-self.minValue>(self.currentMax-self.currentMin)*3/4){
            self.currentMin = self.minValue - (self.maxValue-self.minValue)/2;
            self.currentMax = self.maxValue + (self.maxValue-self.minValue)/2;
            [self.slider setMinimumValue:self.currentMin];
            [self.slider setMaximumValue:self.currentMax];
            self.minValue = 1;
            self.maxValue = 0;
            [self.slider setMinimumTrackTintColor:[UIColor redColor]];
        } else {
            if (self.okCounter>1) {
                [self.slider setMinimumTrackTintColor:nil];
                self.okCounter = 0;
                self.minValue = 1;
                self.maxValue = 0;
            } else {
                self.okCounter++;
            }

        }
        self.count = 0;
    }
    if (redValue<self.currentMin || redValue>self.currentMax) {
        [self.slider setMinimumTrackTintColor:[UIColor redColor]];
    }
    
    self.count++;
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


void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
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

-(void) writeData{
    NSMutableData* data = [NSMutableData data];
    NSString* filePath = [NSString stringWithFormat:@"%@/pulseData.txt", self.docDir];
    for (int i =0; i<[self.list count]; i++) {
        NSString *line  = [NSString stringWithFormat:@"%@\n",[self.list objectAtIndex:i]];
        NSData* dataLine = [line dataUsingEncoding:NSUTF8StringEncoding];
        [data appendData:dataLine];
    }
    [data writeToFile:filePath atomically:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [self tearDownAVCapture];
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

@end
