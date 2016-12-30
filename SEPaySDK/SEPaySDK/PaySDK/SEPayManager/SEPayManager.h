//
//  SEPayManager.h
//  SEPaySDK
//
//  Created by yuan on 16/6/23.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>
#import "SEPayManagerDelegate.h"
#import "UPPayPlugin.h"
#import "UPPayPluginDelegate.h"
/**
 *  支付管理
 */
@interface SEPayManager : NSObject<WXApiDelegate,SEPayManagerDelegate>

/**
 *  管理唯一实例
 *
 *  @return 
 */
+ (instancetype)sharedManager;

@end
