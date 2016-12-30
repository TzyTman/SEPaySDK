//
//  ViewController.m
//  SEPaySDK
//
//  Created by yuan on 16/6/22.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import "ViewController.h"
#import "SEPaylistViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getPayListAction:(id)sender
{
    SEPaylistViewController *sePayListVC =[[SEPaylistViewController alloc] initWithNibName:@"SEPaylistViewController" bundle:nil];
    NSDictionary *param = @{@"created_ts":@"1474441648",
                            @"pay_no":@"P160921001001174",
                            @"se_sign":@"be3dd4c4d927d6b15e1b0f03ede0e5e4"};
    [sePayListVC setGetPayListParam:param];
    sePayListVC.payResultBlock =  ^(BOOL state, SEPayType type, NSError *err, id content) {
        
    };
    [self.navigationController pushViewController:sePayListVC animated:YES];
}
@end
