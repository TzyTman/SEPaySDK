//
//  SEPaylistCell.m
//  SEPaySDK
//
//  Created by yuan on 16/7/1.
//  Copyright © 2016年 yuan. All rights reserved.
//

#import "SEPaylistCell.h"

@implementation SEPaylistCell

- (void)awakeFromNib {
    // Initialization code
}

-(void)setMModel:(SEPayListModel *)mModel
{
        if ([mModel.payment_type_id integerValue] == 1)
        {
            _icon.image = [UIImage imageNamed:@"支付宝"];
            _platform.text = mModel.name;
        }
        else if ([mModel.payment_type_id integerValue] == 2)
        {
    //        _icon.backgroundColor = [UIColor colorWithRed:0.400 green:0.400 blue:1.000 alpha:1.000];
            _icon.image = [UIImage imageNamed:@"银联"];
            _platform.text = mModel.name;
    
        }
        else if ([mModel.payment_type_id integerValue] == 3)
        {
            //        _icon.backgroundColor = [UIColor colorWithRed:0.400 green:0.400 blue:1.000 alpha:1.000];
            _icon.image = [UIImage imageNamed:@"微信"];
            _platform.text = mModel.name;
            
        }
        else
        {
            
        }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
