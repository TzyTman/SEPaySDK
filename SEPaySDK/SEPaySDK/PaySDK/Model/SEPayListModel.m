//
//  SEPayListModel.m
//  SEPaySDK
//
//  Created by yuan on 16/6/24.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import "SEPayListModel.h"

@implementation SEPayListModel

-(id)copyWithZone:(NSZone *)zone
{
    SEPayListModel *custom = [[self class] allocWithZone: zone];
    return custom;
}
@end
