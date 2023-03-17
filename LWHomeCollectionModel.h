//
//  LWHomeCollectionModel.h
//  LinWear
//
//  Created by 裂变智能 on 2022/5/21.
//  Copyright © 2022 lw. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ItemHeight 184.6

NS_ASSUME_NONNULL_BEGIN

@interface LWHomeCollectionModel : NSObject

@property (nonatomic, assign) LWHealthDataType healthDataType;

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *img;

@property (nonatomic, assign) CGFloat itemHeight; // 默认看.m文件中初始化

@end

NS_ASSUME_NONNULL_END
