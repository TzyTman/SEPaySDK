//
//  SEPaylistViewController.h
//  SEPaySDK
//
//  Created by yuan on 16/6/30.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEPaylistCell.h"
#import "SEPayListModel.h"
#import "SEPayManager.h"
#import "SEAliParameterModel.h"
@interface SEPaylistViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView  *merrView;
@property (weak, nonatomic) IBOutlet UILabel *mmoney;
@property (weak, nonatomic) IBOutlet UITableView *mlistView;
@property (copy, nonatomic) SEPublicPayResultBlock payResultBlock;

- (void)setGetPayListParam:(NSDictionary *)parm;
- (void)setAmount:(NSNumber *)amount;
@end
