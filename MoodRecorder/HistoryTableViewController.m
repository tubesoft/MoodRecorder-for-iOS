//
//  HistoryTableViewController.m
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/18.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import "HistoryTableViewController.h"

@interface HistoryTableViewController ()
@property NSMutableArray* recordsArray;
@property NSArray* paths;
@property NSString* docDir;
@property NSString *filePath;

@end

@implementation HistoryTableViewController
@synthesize historyTableView;
@synthesize btnTop;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.btnTop;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    self.docDir = [self.paths objectAtIndex:0];
    self.filePath = [NSString stringWithFormat:@"%@/records.dat", self.docDir];
    
    self.recordsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:self.filePath];
    
    [self refreshTableOnFront];
    
    NSLog(@"全データ数:%@",@([self.recordsArray count]));
}

//フロント側でテーブルを更新
- (void)refreshTableOnFront {
    [self performSelectorOnMainThread:@selector(refreshTable) withObject:self waitUntilDone:TRUE];
}

//テーブルの内容をセット
- (void)refreshTable {
    //ステータスバーのActivity Indicatorを停止
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    //最新の内容にテーブルをセット
    [historyTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.recordsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CELL_IDENTIFIER = @"RecordCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    UILabel *lblDate = (UILabel*)[cell viewWithTag:1];
    UILabel *lblSamplingRate = (UILabel*)[cell viewWithTag:2];
    UILabel *lblIsTracked = (UILabel*)[cell viewWithTag:3];
    
    NSDictionary *dict = [self.recordsArray objectAtIndex:[indexPath row]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    NSDate* date = [[dict valueForKey:@"MeasurementDate"] objectAtIndex:0];
    NSString* dateStr = [formatter stringFromDate:date];
    
    lblDate.text = dateStr;
    lblSamplingRate.text = [NSString stringWithFormat:@"%@ Hz",[[dict valueForKey:@"SamplingRate"] objectAtIndex:0]];
    
    if ([[[dict valueForKey:@"IsTracked"] objectAtIndex:0] isEqual:@"TRUE"]) {
        lblIsTracked.text = @"/w tr";
    } else {
        lblIsTracked.text = @"w/o tr";
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [self.recordsArray objectAtIndex:[indexPath row]];
    NSString *filePath = [NSString stringWithFormat:@"%@/tempData.dat", self.docDir];
    BOOL successful = [NSKeyedArchiver archiveRootObject:dict toFile:filePath];
    if (successful) {
        NSLog(@"%@", @"一時データの保存に成功しました。");
    }
    [self performSegueWithIdentifier:@"FromHistoryToResult" sender:self];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return true;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.recordsArray removeObjectAtIndex:indexPath.row];
    [self saveData];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        // 編集モード時の処理→配列から削除する
    } else {
        // 編集から戻るときの処理
    }
}

-(void)saveData{
    BOOL successful = [NSKeyedArchiver archiveRootObject:self.recordsArray toFile:self.filePath];
    if (successful) {
        NSLog(@"%@", @"データを削除し保存しました。");
    }
    [self saveDataAsTxt:self.recordsArray];
}

-(void)saveDataAsTxt:(NSMutableArray*)array{
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    [formatter2 setDateFormat:@"HH:mm:ss.SSS"];
    NSMutableData *data = [NSMutableData data];
    NSData *dataLine;
    NSString *filePath = [NSString stringWithFormat:@"%@/records.txt", self.docDir];
    CGFloat imageViewWidth = 280;
    
    
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
