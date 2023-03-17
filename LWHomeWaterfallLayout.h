//
//  LWHomeWaterfallLayout.h
//  LinWear
//
//  Created by 裂变智能 on 2022/5/20.
//  Copyright © 2022 lw. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LWHomeWaterfallLayout;

NS_ASSUME_NONNULL_BEGIN

@protocol LWCollectionWaterfallLayoutProtocol <NSObject>

- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForSupplementaryHeaderViewAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForSupplementaryFooterViewAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface LWHomeWaterfallLayout : UICollectionViewLayout

@property (nonatomic, weak) id<LWCollectionWaterfallLayoutProtocol> delegate;
@property (nonatomic, assign) NSUInteger columns;
@property (nonatomic, assign) CGFloat columnSpacing;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) UIEdgeInsets insets;

@end



NS_ASSUME_NONNULL_END
