//
//  ViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/18.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "ViewController.h"
#import <sys/utsname.h>

@interface ViewController ()
@property NSArray* paths;
@property NSString* docDir;
@property NSString* errorMessage;
@property int sampRate;
@property UIAlertController *ac;
@end

@implementation ViewController

@synthesize pickerView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Pickerviewにデリゲートを設定
    self.pickerView.delegate = self;

    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    NSString *settingPath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    
    //設定ファイルが存在しない場合の処理
    if (![[NSFileManager defaultManager] fileExistsAtPath:settingPath]) {
        int sampRate = 20;
        Boolean isTracked = false;
        NSString *sampRateStr = [NSString stringWithFormat:@"%@", @(sampRate)];
        NSString *isTrackedStr = [NSString stringWithFormat:@"%d", isTracked];
        NSArray *array = [NSArray arrayWithObjects:
                          sampRateStr,
                          isTrackedStr,
                          nil];
        BOOL successful = [NSKeyedArchiver archiveRootObject:array toFile:settingPath];
        if (successful) {
            NSLog(@"%@", @"デフォルトのセッティングファイルを作りました。");
        }
    }
}

// 他画面からトップに戻る際に必要
- (IBAction)unwindToTop:(UIStoryboardSegue *)segue
{
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * ピッカーに表示する列数を返す
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

/**
 * ピッカーに表示する行数を返す
 */
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0){
        return 30;
    } else if (component == 1){
        return 60;
    }
    return 60;
}
/**
 * ピッカーに表示する値を返す
 */
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0){
        for (int i=0; i<30; i++) {
            if (row == i){
                return [NSString stringWithFormat:@"%d", i];
            }
        }
    }
    if (component == 1){
        for (int i=0; i<60; i++) {
            if (row == i){
                return [NSString stringWithFormat:@"%d", i];
            }
        }
    }
    
    return Nil;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSArray *array = [NSArray arrayWithObjects:
                      @([self.pickerView selectedRowInComponent:0]),
                      @([self.pickerView selectedRowInComponent:1]),
                      nil];
    NSString *filePath = [NSString stringWithFormat:@"%@/pickerValues.dat", self.docDir];
    BOOL successful = [NSKeyedArchiver archiveRootObject:array toFile:filePath];
    if (successful) {
        NSLog(@"%@", @"ピッカーデータの保存に成功しました。");
    }
}

- (IBAction)touchStart:(id)sender {
    if ([pickerView selectedRowInComponent:0]==0 &&
        [pickerView selectedRowInComponent:1]==0) {
        [self presentViewController:self.ac animated:YES completion:nil];
    } else {
        [self performSegueWithIdentifier:@"FromTopToInstruction" sender:self];
    }
}

- (IBAction)touchCombMeasurement:(id)sender {
    NSString *deviceName = getDeviceName();
    NSString *filePath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    NSArray *settingArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    NSString *sampRateStr = [settingArray objectAtIndex:0];
    self.sampRate = [sampRateStr intValue];

    
    if ([pickerView selectedRowInComponent:0]==0 &&
        [pickerView selectedRowInComponent:1]==0) {
        self.errorMessage = @"The measurement time cannot be zero.";
        [self createAlert];
        [self presentViewController:self.ac animated:YES completion:nil];
    } else {
        Boolean canMeasure = true;
        //iPhone5以下の場合
        if ([UIScreen mainScreen].bounds.size.height<=400 || [deviceName hasPrefix:@"iPhone5,"]) {
            if (self.sampRate>60) {
                canMeasure = false;
                self.errorMessage = @"Sampling rate should be set less than 60 Hz for iPhone 5 or less.";
                [self createAlert];
                [self presentViewController:self.ac animated:YES completion:nil];
                
            }
        }
        //iPhone5sの場合
        if ([deviceName hasPrefix:@"iPhone6,"]) {
            if (self.sampRate>120){
                canMeasure = false;
                self.errorMessage = @"Sampling rate should be set less than 120 Hz for iPhone 5 or less.";
                [self createAlert];
                [self presentViewController:self.ac animated:YES completion:nil];
            }
        }
        if (canMeasure) {
            [self performSegueWithIdentifier:@"FromTopToCombMeasurement" sender:self];
        }
    }
}

- (IBAction)touchPulseWave:(id)sender {
    NSString *deviceName = getDeviceName();
    NSString *filePath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    NSArray *settingArray = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    NSString *sampRateStr = [settingArray objectAtIndex:0];
    self.sampRate = [sampRateStr intValue];
    Boolean canMeasure = true;
    
    //iPhone5以下の場合
    if ([UIScreen mainScreen].bounds.size.height<=400 || [deviceName hasPrefix:@"iPhone5,"]) {
        if (self.sampRate>60) {
            canMeasure = false;
            self.errorMessage = @"Sampling rate should be set less than 60 Hz for iPhone 5 or less.";
            [self createAlert];
            [self presentViewController:self.ac animated:YES completion:nil];
            
        }
    }
    //iPhone5sの場合
    if ([deviceName hasPrefix:@"iPhone6,"]) {
        if (self.sampRate>120){
            canMeasure = false;
            self.errorMessage = @"Sampling rate should be set less than 120 Hz for iPhone 5 or less.";
            [self createAlert];
            [self presentViewController:self.ac animated:YES completion:nil];
        }
    }
    if (canMeasure) {
        [self performSegueWithIdentifier:@"FromTopToPulse" sender:self];
    }


}

-(void)createAlert{
    // コントローラを生成
    self.ac =
    [UIAlertController alertControllerWithTitle:@"Warning"
                                        message:self.errorMessage
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action) {
                               // ボタンタップ時の処理
                           }];
    [self.ac addAction:okAction];
}

// モデル名を取得する
NSString* getDeviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}
@end
