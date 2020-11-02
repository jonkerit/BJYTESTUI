//
//  BJLScLotteryUserCell.m
//  BJLiveUI
//
//  Created by xyp on 2020/8/27.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLScLotteryUserCell.h"
#import <BJLiveBase/BJLiveBase.h>

@interface BJLScLotteryUserCell()

@property (nonatomic) UILabel *nameLabel, *prizeLabel;

@end

@implementation BJLScLotteryUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self makeViews];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.nameLabel.text = @"";
    self.prizeLabel.text = @"";
}


- (void)updateWithUserName:(NSString *)userName prizeName:(NSString *)prizeName {
    self.nameLabel.text = userName;
    self.prizeLabel.text = prizeName;
}

- (void)makeViews {
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1.0;
        label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, nameLabel);
        label;
    });
    
    self.prizeLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1.0;
        label.textColor = [UIColor bjl_colorWithHexString:@"#AE6008"];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentRight;
        label.accessibilityLabel = BJLKeypath(self, prizeLabel);
        label;
    });
    
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.prizeLabel];
    
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.left.equalTo(self.contentView);
        make.right.equalTo(self.contentView.bjl_centerX);
    }];
    
    [self.prizeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.right.equalTo(self.contentView);
        make.left.equalTo(self.contentView.bjl_centerX);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
