//
//  SEPayManager.m
//  SEPaySDK
//
//  Created by yuan on 16/6/23.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import "SEPayManager.h"
#import "SEPayListModel.h"
#import "SEAliParameterModel.h"
#import "SEPaylistViewController.h"
#import "UPPaymentControl.h"

#define kCallbackDicKey @"Callback"
#define kMode_Development             @"01" //银联 测试环境参数01  测试环境参数00


@interface SEPayManager()
{
    NSMutableDictionary* _payCallbackDic;  //存储callback状态block
    NSString * _notify_url;           //临时存储_notify_url
}

@property (nonatomic, strong) UIViewController *payVC;
@property (nonatomic, strong) NSURLSession  *mSession;

@end

@implementation SEPayManager

+(instancetype)sharedManager
{
    static dispatch_once_t oncetoken;
    static SEPayManager * instance;
    dispatch_once(&oncetoken, ^{
        instance = [[SEPayManager alloc] init];
    });
    return instance;
}


-(instancetype)init
{
    if (self = [super init])
    {
        _payCallbackDic = [NSMutableDictionary new];
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _mSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

#pragma mark --------------  获取支付列表请求操作
-(void)GetPayListDataBypayParam:(NSDictionary *)payParam callbackResult:(SEPayResultBlock)result
{
    _payCallbackDic[kCallbackDicKey] = result;
    NSURLRequest *request;
    if (payParam == nil)
    {
        NSLog(@"订单号不能为空");
        result(NO, [NSError errorWithDomain:@"" code:-1 userInfo:@{@"error":@"订单号不能为空"}], nil);
    }
    
    //处理参数，把参数拼接为字符串
    NSString *str = @"";
    NSMutableArray *paris = [NSMutableArray array];
    
    for (NSString *key in payParam) {
        str = [NSString stringWithFormat:@"%@=%@",key, payParam[key]];
        [paris addObject:str];
    }
    str = [paris componentsJoinedByString:@"&"];
    
    request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", kPayURL, str]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];

    NSURLSessionDataTask *dataTask = [_mSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                      {
                                          SEPayResultBlock callback = _payCallbackDic[kCallbackDicKey];
                                          if (!error)
                                          {
                                              NSHTTPURLResponse * httpResp = (NSHTTPURLResponse*)response;
                                              if (httpResp.statusCode == 200)
                                              {
                                                  NSError * jsonErr;
                                                  NSDictionary * notesJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonErr];
                                                  //返回格式错误
                                                  if (!jsonErr)
                                                  {
                                                      if ([[notesJSON valueForKey:@"code"] integerValue] == 200)
                                                      {
                                                          NSArray * arr = [notesJSON objectForKey:@"data"];
                                                          if (callback)
                                                          {
                                                              callback(YES, nil, arr);
                                                          }
                                                      }
                                                      else
                                                      {
                                                          callback(NO, jsonErr, nil);
                                                      }
                                                  }
                                                  else
                                                  {
                                                      callback(NO, jsonErr, nil);
                                                  }
                                              }
                                              else
                                              {
                                                  //httpResp.statusCode ！= 200统一作服务器异常处理
                                                  callback(NO, [NSError errorWithDomain:@"" code:httpResp.statusCode userInfo:@{@"error":@"服务器异常"}], nil);
                                              }
                                          }
                                          else//网络出错
                                          {
                                              NSLog(@"%@", error);
                                              callback(NO, error, nil);
                                          }
                                         // [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                                          
                                      }];
    [dataTask resume];
}


/**
 *  注册平台
 *
 *  @param key
 *  @param type
 *
 *  @return
 */
-(BOOL)registerAppwithKey:(NSString *)key platform:(SEPayType)type
{
    if (type == kSEAliPayPlatform)
    {
        return YES;
    }
    else if (type == kSEWXPayPlatform)
    {
        if (key == nil)
        {
            return NO;
        }
        else
        {
            return  [WXApi registerApp:@""];
        }
    }
    return NO;
}


/**
 *  打开第三方平台进行支付
 *
 *  @param url
 */
-(void)applicationOpenURL:(NSURL *)url
{
    if ([url.host isEqualToString:@"safepay"])
    {
        SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            if ([[resultDic objectForKey:@"resultStatus"] integerValue] == 9000)
            {
                if (result)
                {
                    result(YES, nil, [resultDic objectForKey:@"result"]);
                    [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                    //回执异步通知后台 opg
                    if (_notify_url)
                    {
                        [self sendPayBack:[resultDic objectForKey:@"result"] withUrl:_notify_url];
                    }
                }
            }
            else
            {
                if (result)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[resultDic objectForKey:@"result"] forKey:NSLocalizedDescriptionKey];
                    result(NO, [NSError errorWithDomain:@"" code:[[resultDic objectForKey:@"resultStatus"] integerValue] userInfo:userInfo], nil);                    
                    [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                }
            }
        }];
    }else if ([url.host isEqualToString:@"uppayresult"]) {
      
        SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];

        [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
            
            //结果code为成功时，先校验签名，校验成功后做后续处理
            if([code isEqualToString:@"success"]) {
               
                if (result)
                {
                    result(YES, nil,code);
                }
               
                //判断签名数据是否存在
                if(data == nil){
                    //如果没有签名数据，建议商户app后台查询交易结果
                    return;
                }
                
                //数据从NSDictionary转换为NSString
                NSData *signData = [NSJSONSerialization dataWithJSONObject:data
                                                                   options:0
                                                                     error:nil];
                NSString *sign = [[NSString alloc] initWithData:signData encoding:NSUTF8StringEncoding];
                
            
                //验签证书同后台验签证书
                //此处的verify，商户需送去商户后台做验签
                if([self verify:sign]) {
                    //支付成功且验签成功，展示支付成功提示
                }
                else {
                    //验签失败，交易结果数据被篡改，商户app后台查询交易结果
                }
            }
            else if([code isEqualToString:@"fail"]) {
                
                if (result) {
                    //交易失败
                    result(NO, nil,code);
                }
              
            }
            else if([code isEqualToString:@"cancel"]) {
                if (result) {
                    //交易失败
                    result(NO, nil,code);
                }
            }
        }];
    } else
    {
        [WXApi handleOpenURL:url delegate:self];
    }
}

-(void)applicationDidBecomeActive{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationBecomeActive" object:nil];
}

-(BOOL)verify:(NSString *) resultStr {
    //验签证书同后台验签证书
    //此处的verify，商户需送去商户后台做验签
    return NO;
}

/**
 *  处理支付成功回执，发送给opg
 *
 *  @param result 支付结果
 *  @param url    URL
 */
-(void)sendPayBack:(NSString*)result withUrl:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",url,result]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
    NSURLSessionDataTask *dataTask = [_mSession dataTaskWithRequest:request];
    [dataTask resume];
}

#pragma mark -------------------  微信支付回调代理 WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    
    if ([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        
    }
    else if ([resp isKindOfClass:[SendAuthResp class]])
    {
        
    }
    else if ([resp isKindOfClass:[AddCardToWXCardPackageResp class]])
    {
        
    }
    else if([resp isKindOfClass:[PayResp class]])
    {
        SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];
        
        //支付返回结果，实际支付结果需要去微信服务器端查询
        NSString *strMsg,*strTitle = [NSString stringWithFormat:@"支付结果"];
        
        switch (resp.errCode) {
            case WXSuccess:
                if (result)
                {
                    result(YES, nil, nil);
                    [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                }
                strMsg = @"支付结果：成功！";
                NSLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                if (result)
                {
                    result(NO, [NSError errorWithDomain:@"" code:resp.errCode userInfo:@{@"error":@"支付失败"}], nil);
                    [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                }
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
    }
}


#pragma mark --------------  支付流程  支付宝 微信
/**
 *   1.获取支付参数并发起支付请求
 *
 *  @param type   支付类型
 *  @param result 返回结果
 */
-(void)payOrderwithPlatform:(SEPayType)type payNo:(NSString *)payNo payVC:(UIViewController *)payVC callBackResult:(SEPayResultBlock)result
{
    //当前支付控制器
    self.payVC = payVC;
    
    //获取支付参数
    [self getPayParameterWithPlatform:type payNo:payNo withResult:^(BOOL state, NSError *err, id content) {
        if (state)
        {
            //成功获取支付参数，更具类型组装参数
            id  parameter = nil;
            if (type == kSEAliPayPlatform)
            {
                parameter = [self aliParameter:content];
                NSLog(@"%@", parameter);
            }
            else if (type == kSEWChinaUnionPay)
            {
                parameter  =  content;
                NSLog(@"%@", parameter);
            }
            else if (type == kSEWXPayPlatform)
            {
                parameter = [self wxParameter:content];
            }
            else
            {
            }
            // 开始支付
            [self sendOrder:parameter withPlatform:type callBackResult:result];
        }
        else
        {
            if (result)
            {
                result(NO, err, nil);
            }
        }
    }];
}

/**
 *  2. 获取支付参数
 *
 *  @param type   支付平台类型
 *  @param result
 */
-(void)getPayParameterWithPlatform:(SEPayType)type payNo:(NSString *)payNo withResult:(SEPayResultBlock)result
{
    NSInteger Platform = 0xff;
    switch (type)
    {
        case kSEAliPayPlatform:
            Platform = 1;
            break;
        case kSEWChinaUnionPay:
            Platform = 2;
            break;
        case kSEWXPayPlatform:
            Platform = 3;
            break;
        default:
            result(NO,[NSError errorWithDomain:@"" code:-1 userInfo:@{@"error":@"暂不支持该平台"}], nil);
            break;
    }
    NSString *str = [NSString stringWithFormat:@"payment_type_id=%ld&pay_no=%@", Platform, payNo];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",kPayURL, str]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
    NSURLSessionDataTask *dataTask = [_mSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
                                      {
                                          if (!error)
                                          {
                                              NSHTTPURLResponse * httpResp = (NSHTTPURLResponse*)response;
                                              if (httpResp.statusCode == 200)
                                              {
                                                  NSError * jsonErr;
                                                  NSDictionary * notesJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonErr];
                                                  if (!jsonErr)
                                                  {
                                                      if (result)
                                                      {
                                                          result(YES, nil, [notesJSON valueForKey:@"data"]);
                                                      }
                                                      else
                                                      {
                                                          result(NO, [NSError errorWithDomain:@"" code:-1 userInfo:@{@"error":jsonErr.localizedDescription}], nil);
                                                      }
                                                  }
                                              }
                                              else
                                              {
                                                  result(NO, [NSError errorWithDomain:@"" code:httpResp.statusCode userInfo:nil], nil);
                                              }
                                          }
                                          else
                                          {
                                              result(NO, error, nil);
                                          }          
                                      }];
    [dataTask resume];
}


/**
 *  3.开始支付
 *
 *  @param obj
 *  @param type
 *  @param result
 */
-(void)sendOrder:(id)obj withPlatform:(SEPayType)type callBackResult:(SEPayResultBlock)result
{
    if (obj == nil)
    {
        NSLog(@"invalue parameter");
        return;
    }
    if (result)
    {
        _payCallbackDic[kCallbackDicKey] = result;
    }
    
    if (type == kSEAliPayPlatform)
    {
        [self payAliOrder:obj withPlatform:type];
    }
    else if (type == kSEWXPayPlatform)
    {
        [self payWXOrder:obj withPlatform:type];
        
    }else if (type == kSEWChinaUnionPay)
    {
        [self unionPayPayment:(NSString *)obj];
    }
    else if (type == kSEOtherPlatform)
    {
        result(NO,[NSError errorWithDomain:@"" code:-1 userInfo:@{@"error":@"暂不支持该平台"}], nil);
    }
}


/**
 *  支付宝 支付
 *
 *  @param obj
 *  @param type
 */
-(void)payAliOrder:(id)obj withPlatform:(SEPayType)type
{
    SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];
    //应用注册schemeInfo.plist定义URL types
    [[AlipaySDK defaultService] payOrder:obj fromScheme:kappScheme callback:^(NSDictionary *resultDic)
     {
         NSLog(@"支付结果:%@", resultDic);
         if ([[resultDic objectForKey:@"resultStatus"] integerValue] == 9000)
         {
             if (result)
             {
                 result(YES, nil, [resultDic objectForKey:@"result"]);
                 [_payCallbackDic removeObjectForKey:kCallbackDicKey];
                 //回执异步通知后台 opg
                 if (_notify_url)
                 {
                     [self sendPayBack:[resultDic objectForKey:@"result"] withUrl:_notify_url];
                 }
             }
         }
         else
         {
             if (result)
             {
                 NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[resultDic objectForKey:@"result"] forKey:NSLocalizedDescriptionKey];
                 result(NO, [NSError errorWithDomain:@"" code:[[resultDic objectForKey:@"resultStatus"] integerValue] userInfo:userInfo], nil);
                 
                 [_payCallbackDic removeObjectForKey:kCallbackDicKey];
             }
         }
     }];
}

/**
 *  微信支付
 *
 *  @param obj
 *  @param type
 */
-(void)payWXOrder:(id)obj withPlatform:(SEPayType)type
{
    if (![obj isKindOfClass:[PayReq class]])
    {
        NSLog(@"invalue parameter type");
    }
    
    PayReq *pay  = obj;
    
    if (![pay.prepayId isKindOfClass:[NSNull class]] && pay.prepayId.length>0 ) {
        
        if([WXApi isWXAppInstalled]) {
            
            //发起支付
            [WXApi sendReq:obj];
            
        }else {
            SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];
            result(NO , nil , @"请安装微信客户端");
        }
        
    }else {
    
         SEPayResultBlock result = _payCallbackDic[kCallbackDicKey];
         result(NO , nil , @"prepayId不能为空!");
    }
}

/**
 *  银联支付
 *
 *  @param tn 交易流水号，商户后台向银联后台提交订单信息后,由银联后台生成并下发给商户后台的交易凭证；
 */
- (void)unionPayPayment:(NSString *)tn {
    
    if (tn != nil && tn.length > 0) {
       NSLog(@"tn=%@",tn);
       [[UPPaymentControl defaultControl] startPay:tn fromScheme:@"SEPaySDK" mode:kMode_Development viewController:self.payVC];
    }
}

#pragma mark ------------- 支付参数封装  微信  支付宝

/**
 *  支付宝支付参数
 *
 *  @param dic
 *
 *  @return
 */
-(NSString *)aliParameter:(NSDictionary *)dic
{
    if (dic == nil)
    {
        return nil;
    }
    SEAliParameterModel * model = [SEAliParameterModel new];
    model.service = [dic objectForKey:@"service"];
    model.partner = [dic objectForKey:@"partner"];
    model._input_charset = [dic objectForKey:@"_input_charset"];
    model.sign_type = [dic objectForKey:@"sign_type"];
    model.sign = [dic objectForKey:@"sign"];
    model.body = [dic objectForKey:@"body"];
    model.notify_url = [dic objectForKey:@"notify_url"];
    model.app_id = [dic objectForKey:@"app_id"];
    model.appenv = [dic objectForKey:@"appenv"];
    model.out_trade_no = [dic objectForKey:@"out_trade_no"];
    model.subject = [dic objectForKey:@"subject"];
    model.payment_type = [dic objectForKey:@"payment_type"];
    model.seller_id = [dic objectForKey:@"seller_id"];
    model.total_fee = [dic objectForKey:@"total_fee"];
    model.goods_type = [dic objectForKey:@"goods_type"];
    model.hb_fq_param = [dic objectForKey:@"hb_fq_param"];
    model.rn_check = [dic objectForKey:@"rn_check"];
    model.it_b_pay = [dic objectForKey:@"it_b_pay"];
    model.extern_token = [dic objectForKey:@"extern_token"];
    
    _notify_url = model.notify_url;
    return [model description];
}

/**
 *  微信 支付参数
 *
 *  @param dict
 *
 *  @return 
 */
-(PayReq *)wxParameter:(NSDictionary *)dict
{
//  NSString * time = [NSString stringWithFormat:@"%.f",[[NSDate date] timeIntervalSince1970]];
    PayReq * req = [PayReq new];
    req.partnerId           = [dict objectForKey:@"partnerid"];
    req.prepayId            = [dict objectForKey:@"prepayid"];
    req.nonceStr            = [dict objectForKey:@"noncestr"];
    req.package             = @"Sign=WXPay";//
    req.sign                = [dict objectForKey:@"sign"];
    req.timeStamp = [[dict objectForKey:@"timestamp"] intValue];
    return req;
}

@end
