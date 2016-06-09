//
//  SettingViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/19.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()
@property NSArray* paths;
@property NSString* docDir;
@property NSMutableArray* settingArray;
@property NSString* sampRateStr;
@property NSString* isTrackedStr;
@property NSString *filePath;
@end

@implementation SettingViewController
@synthesize pickerSampRate;
@synthesize switchTracking;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Pickerviewにデリゲートを設定
    self.pickerSampRate.delegate = self;
    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    self.filePath = [NSString stringWithFormat:@"%@/setting.dat", self.docDir];
    self.settingArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.filePath];
    self.sampRateStr = [self.settingArray objectAtIndex:0];
    int sampRate = [self.sampRateStr intValue]/10-1;
    self.isTrackedStr = [self.settingArray objectAtIndex:1];
    Boolean isTracked = [self.isTrackedStr boolValue];
    [pickerSampRate selectRow:sampRate inComponent:0 animated:0];
    [switchTracking setOn:isTracked];
    
}


/**
 * ピッカーに表示する列数を返す
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

/**
 * ピッカーに表示する行数を返す
 */
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return 20;
}
/**
 * ピッカーに表示する値を返す
 */
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0){
        for (int i=0; i<20; i++) {
            if (row == i){
                return [NSString stringWithFormat:@"%d", 10+i*10];
            }
        }
    }
    return Nil;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    NSString *str = [NSString stringWithFormat:@"%@", @([pickerSampRate selectedRowInComponent:0]*10+10)];
    self.sampRateStr = str;
    [self saveSetting];
}

- (IBAction)actionSwitch:(id)sender {
    NSString *str = [NSString stringWithFormat:@"%d",[switchTracking isOn]];
    self.isTrackedStr = str;
    [self saveSetting];
}

-(void)saveSetting{
    NSMutableArray *array = [NSMutableArray arrayWithObjects:
                             self.sampRateStr,
                             self.isTrackedStr,
                             nil];
    self.settingArray = array;
    BOOL successful = [NSKeyedArchiver archiveRootObject:self.settingArray toFile:self.filePath];
    if (successful) {
        NSLog(@"%@", @"セッティングの保存に成功しました。");
    }
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
