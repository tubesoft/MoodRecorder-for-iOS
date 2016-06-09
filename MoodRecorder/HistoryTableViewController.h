//
//  HistoryTableViewController.h
//  MoodRecorder
//
//  Created by Takatomo INOUE on 2016/05/18.
//  Copyright © 2016年 Takatomo INOUE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UITableView *historyTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnTop;

@end
