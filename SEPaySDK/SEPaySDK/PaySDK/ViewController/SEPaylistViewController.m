//
//  SEPayViewController.m
//  SEPaySDK
//
//  Created by yuan on 16/6/24.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import "SEPaylistViewController.h"
#define kSEPaylistCell @"SEPaylistCell"


@interface SEPaylistViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray * _listArr;
    
    UIActivityIndicatorView * _activityIndicatorView;
    
    UIAlertController *_alertController;
    
    NSDictionary *_payListParam;
    NSNumber *_amount;
    NSString *_payNo;  //储存交易号
}

@end

@implementation SEPaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"支付列表";
    
    _listArr = [NSMutableArray new];
    
    [_mlistView registerNib:[UINib nibWithNibName:@"SEPaylistCell" bundle:nil] forCellReuseIdentifier:kSEPaylistCell];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    _activityIndicatorView.center = self.view.center;
    [_activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [_activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_activityIndicatorView setBackgroundColor:[UIColor lightGrayColor]];
    [_activityIndicatorView setHidesWhenStopped:YES];
    [self.view addSubview:_activityIndicatorView];
    _merrView.hidden = YES;
    
    _alertController = [UIAlertController alertControllerWithTitle:@"标题" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self.navigationController popViewControllerAnimated:YES];
    }];
    [_alertController addAction:okAction];
    
    
    [_activityIndicatorView startAnimating];
    
    _payNo = [_payListParam objectForKey:@"pay_no"];
    _mmoney.text = [_amount stringValue];
    /* 获取支付列表请求 */
    [[SEPayManager sharedManager] GetPayListDataBypayParam:_payListParam callbackResult:^(BOOL state, NSError *err, id content) {
        NSLog(@"%@", content);
        
        if (state) { //成功获取
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_activityIndicatorView stopAnimating];
                _merrView.hidden = YES;
            });
            
            NSArray * arr = [content copy];
            
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                SEPayListModel * model = [SEPayListModel new];
                model.name = [obj objectForKey:@"name"];
                model.payment_type_id = [obj objectForKey:@"payment_type_id"];
                [_listArr addObject:model];
                if (idx == [arr count] - 1)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_mlistView reloadData];
                    });
                }
            }];
        }
        else//失败
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_activityIndicatorView stopAnimating];
                _merrView.hidden = NO;
            });
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)setGetPayListParam:(NSDictionary *)parm{
   
    _payListParam = parm;
}

- (void)setAmount:(NSNumber *)amount{
    _amount = amount;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_listArr count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SEPaylistCell * cell = (SEPaylistCell*)[tableView dequeueReusableCellWithIdentifier:kSEPaylistCell forIndexPath:indexPath];
    SEPayListModel * model = [_listArr objectAtIndex:indexPath.row];
    [cell setMModel:model];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_listArr enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row] options:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        SEPayListModel * model = obj;
        [self payWithType:model.payment_type_id];
    }];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/**
 根据支付类型进行支付
 
 @param payMentType 支付平台类型
 */
- (void)payWithType:(NSString *)payMentType{
    
    [_activityIndicatorView startAnimating];
    if ([payMentType integerValue] == 1)
    {
        [[SEPayManager sharedManager] payOrderwithPlatform:kSEAliPayPlatform payNo:_payNo payVC:self callBackResult:^(BOOL state, NSError *err, id content) {
            
            [self paySuccessOrFailureResult:state payError:err payContent:content SEPayType:kSEAliPayPlatform];
            
        }];
    } else if([payMentType integerValue] == 3) {
        if (![WXApi isWXAppInstalled]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [_alertController setTitle:@"未安装微信客户端"];
                [self presentViewController:_alertController animated:YES completion:^{
                    
                }];
            });
        }else{
            [[SEPayManager sharedManager] payOrderwithPlatform:kSEWXPayPlatform payNo:_payNo payVC:self callBackResult:^(BOOL state, NSError *err, id content) {
                
                [self paySuccessOrFailureResult:state payError:err payContent:content SEPayType:kSEWXPayPlatform];
                
            }];
        }
    }else if ([payMentType integerValue]==2) {
        
        [[SEPayManager sharedManager] payOrderwithPlatform:kSEWChinaUnionPay payNo:_payNo payVC:self callBackResult:^(BOOL state, NSError *err, id content) {
            
            [self paySuccessOrFailureResult:state payError:err payContent:content SEPayType:kSEWChinaUnionPay];
            
        }];
    }
}

/**
 * 回到app，若有加载框，则隐藏
 *
 */
- (void)handleBecomeActive{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityIndicatorView stopAnimating];
    });
}

/**
  支付 成功 失败 返回结果

 @param payState 支付状态
 @param error    错误信息
 @param content  内容
 @param type     
 */
- (void)paySuccessOrFailureResult:(BOOL)payState payError:(NSError *)error payContent:(id)content SEPayType:( SEPayType)type  {
    
    if (_payResultBlock) {
        _payResultBlock(payState,type,error,content);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:NO];
    });
    
//    if (payState) {
//        NSLog(@"支付成功");
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [_alertController setTitle:content];
//            [self presentViewController:_alertController animated:YES completion:nil];
//
//        });
//    }
//    else {
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"支付失败");
//            NSString *errorStr = @"";
//            if (content == nil) {
//                errorStr = @"支付失败";
//            }else {
//                errorStr  = content;
//            }
//            
//            [_alertController setTitle:errorStr];
//            [self presentViewController:_alertController animated:YES completion:nil];
//        });
//    }
}

- (BOOL)isVisble{
    
    return(self.isViewLoaded && self.view.window);
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
