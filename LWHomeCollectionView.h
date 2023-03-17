//
//  LWHomeCollectionView.h
//  LinWear
//
//  Created by lw on 2020/5/27.
//  Copyright © 2020 lw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LWHomeWaterfallLayout.h"
#import "LWSportsHealthModel.h"
#import "LWHomeDataCollectionModel.h" // 首页数据集合

NS_ASSUME_NONNULL_BEGIN
@protocol LWHomeCollectionViewDelegate <NSObject>

@optional
- (void)customScrollViewDidScroll:(UIScrollView *)scrollView;

@end

@interface LWHomeCollectionView : UICollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(LWHomeWaterfallLayout *)layout;

@property (nonatomic, strong) LWSportsHealthModel *sportsHealthModel;

@property (nonatomic, strong) LWHomeDataCollectionModel *homeDataCollectionModel;

@property (nonatomic, weak) id<LWHomeCollectionViewDelegate> customDelegate;

/** 刷新数据源 */
- (void)reloadCollectionViewData;

@end

NS_ASSUME_NONNULL_END
