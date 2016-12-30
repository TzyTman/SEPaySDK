//
//  SEWXParameterModel.h
//  SEPaySDK
//
//  Created by yuan on 16/6/27.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  微信支付参数model
 */

@interface SEWXParameterModel : NSObject
@property(nonatomic, copy)NSString * appid; //应用ID
@property(nonatomic, copy)NSString * mch_id; //商户号
@property(nonatomic, copy)NSString * device_info; //设备号
@property(nonatomic, copy)NSString * nonce_str; //随机字符串
@property(nonatomic, copy)NSString * sign; //签名
@property(nonatomic, copy)NSString * body; //商品描述
@property(nonatomic, copy)NSString * detail; //商品详情
@property(nonatomic, copy)NSString * attach; //附加数据
@property(nonatomic, copy)NSString * out_trade_no; //商户订单号
@property(nonatomic, copy)NSString * fee_type; //货币类型
@property(nonatomic, copy)NSString * total_fee; //总金额
@property(nonatomic, copy)NSString * spbill_create_ip; //终端IP
@property(nonatomic, copy)NSString * time_start; //交易起始时间
@property(nonatomic, copy)NSString * time_expire; //交易结束时间
@property(nonatomic, copy)NSString * goods_tag; //商品标记
@property(nonatomic, copy)NSString * notify_url; //通知地址
@property(nonatomic, copy)NSString * trade_type; //交易类型
@property(nonatomic, copy)NSString * limit_pay; //指定支付方式

@end
