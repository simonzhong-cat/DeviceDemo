//
//  LWHomeWaterfallLayout.m
//  LinWear
//
//  Created by 裂变智能 on 2022/5/20.
//  Copyright © 2022 lw. All rights reserved.
//

#import "LWHomeWaterfallLayout.h"

NSString *const kSupplementaryViewKindHeader = @"UICollectionElementKindSectionHeader";
NSString *const kSupplementaryViewKindFooter = @"UICollectionElementKindSectionFooter";
CGFloat const kSupplementaryViewKindHeaderPinnedHeight = 0.f; // 如果需要悬浮，改此参数，改多少悬浮多少

@interface LWHomeWaterfallLayout()

/** 保存所有Item的LayoutAttributes */
@property (nonatomic, strong) NSMutableArray <UICollectionViewLayoutAttributes *> *attributesArray;
/** 保存所有列的当前高度 */
@property (nonatomic, strong) NSMutableArray <NSNumber *> *columnHeights;

@property (nonatomic, assign) CGFloat tempY;

@property (nonatomic, strong) NSIndexPath *headerIndexPath; // 需要有头部时，记录有高度的indexPath

@property (nonatomic, strong) NSIndexPath *footerIndexPath; // 需要有尾部时，记录有高度的indexPath

@end

@implementation LWHomeWaterfallLayout

- (instancetype)init
{
    if(self = [super init]) {
        _columns = 2;
        _columnSpacing = 16;
        _itemSpacing = 16;
        _insets = UIEdgeInsetsMake(6, 12, 12, 12);
    }
    return self;
}

#pragma mark - UICollectionViewLayout (UISubclassingHooks)
/**
 *  1、
 *  collectionView初次显示或者调用invalidateLayout方法后会调用此方法
 *  触发此方法会重新计算布局，每次布局也是从此方法开始
 *  在此方法中需要做的事情是准备后续计算所需的东西，以得出后面的ContentSize和每个item的layoutAttributes
 */
- (void)prepareLayout
{
    [super prepareLayout];
    
    
    //初始化数组
    self.columnHeights = [NSMutableArray array];
    for(NSInteger column=0; column<_columns; column++){
        self.columnHeights[column] = @(0);
    }
    
    
    self.attributesArray = [NSMutableArray array];
    NSInteger numSections = [self.collectionView numberOfSections];
    for(NSInteger section=0; section<numSections; section++){
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item=0; item<numItems; item++){
            //遍历每一项
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            //计算LayoutAttributes
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            
            [self.attributesArray addObject:attributes];
        }
    }
}

/**
 *  2、
 *  需要返回所有内容的滚动长度
 */
- (CGSize)collectionViewContentSize
{
    NSInteger mostColumn = [self columnOfMostHeight];
    //所有列当中最大的高度
    CGFloat mostHeight = [self.columnHeights[mostColumn] floatValue];
    return CGSizeMake(self.collectionView.bounds.size.width, mostHeight+_insets.top+_insets.bottom);
}

/**
 *  3、
 *  当CollectionView开始刷新后，会调用此方法并传递rect参数（即当前可视区域）
 *  我们需要利用rect参数判断出在当前可视区域中有哪几个indexPath会被显示（无视rect而全部计算将会带来不好的性能）
 *  最后计算相关indexPath的layoutAttributes，加入数组中并返回
 */
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributesArray = self.attributesArray;
    NSArray<NSIndexPath *> *indexPaths;
    //1、计算rect中出现的items
    indexPaths = [self indexPathForItemsInRect:rect];
    for(NSIndexPath *indexPath in indexPaths){
        //计算对应的LayoutAttributes
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    //2、计算rect中出现的SupplementaryViews
    indexPaths = [self indexPathForSupplementaryViewsOfKind:kSupplementaryViewKindHeader InRect:rect];
    for(NSIndexPath *indexPath in indexPaths){
        //计算对应的LayoutAttributes
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kSupplementaryViewKindHeader atIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    indexPaths = [self indexPathForSupplementaryViewsOfKind:kSupplementaryViewKindFooter InRect:rect];
    for(NSIndexPath *indexPath in indexPaths){
        //计算对应的LayoutAttributes
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kSupplementaryViewKindFooter atIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }
    
    return attributesArray;
}

/**
 *  每当offset改变时，是否需要重新布局，newBounds为offset改变后的rect
 *  瀑布流中不需要，因为滑动时，cell的布局不会随offset而改变
 *  如果需要实现悬浮Header，需要改为YES
 */
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
//    return [super shouldInvalidateLayoutForBoundsChange:newBounds];
    return YES;
}

#pragma mark - 计算单个indexPath的LayoutAttributes
/**
 *  根据indexPath，计算对应的LayoutAttributes
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    // 外部返回Item高度
    CGFloat itemHeight = [self.delegate collectionViewLayout:self heightForItemAtIndexPath:indexPath];
    
    // headerView高度
    CGFloat headerHeight = [self.delegate collectionViewLayout:self heightForSupplementaryHeaderViewAtIndexPath:indexPath];
    if (headerHeight > 0) {
        self.headerIndexPath = indexPath;
    }
    
    // footerView高度
    CGFloat footerHeight = [self.delegate collectionViewLayout:self heightForSupplementaryFooterViewAtIndexPath:indexPath];
    if (footerHeight > 0) {
        self.footerIndexPath = indexPath;
    }
    
    // 找出所有列中高度最小的
    NSInteger columnIndex;
    
    //计算LayoutAttributes
    CGFloat width;
    if (indexPath.section == 0) { // 这里定制处理，只有一列
        width = (self.collectionView.bounds.size.width-(_insets.left+_insets.right));
        columnIndex = 0;
    } else { // 多列
        width = (self.collectionView.bounds.size.width-(_insets.left+_insets.right)-_columnSpacing*(_columns-1)) / _columns;
        columnIndex = indexPath.row%2==0 ? 0 : 1;
    }
    
    // 找出所有列中高度最小的
    CGFloat lessHeight = [self.columnHeights[columnIndex] floatValue]; // columnIndex==1?0:columnIndex
    
    CGFloat height = itemHeight;
    CGFloat x = _insets.left+(width+_columnSpacing)*columnIndex;
    CGFloat y = lessHeight==0 ? headerHeight+_insets.top : lessHeight+_itemSpacing;
    if (indexPath.section==1 && indexPath.row==1) { // 第二组开始才是瀑布，第二个y应该跟随第一个y
        y = self.tempY;
    }
    self.tempY = y;
    
    attributes.frame = CGRectMake(x, y, width, height);
    
    // 更新列高度
    self.columnHeights[columnIndex] = @(y+height);
    
    // 最高列的高度，避免尾部视图被挤压，尾部视图应该跟随最高那一列
    if (footerHeight > 0) {
        NSInteger highestColumn =  [self columnOfMostHeight];
        CGFloat columnHeight = self.columnHeights[highestColumn].floatValue;
        // 再次更新列高度（此时加上尾部高度）
        self.columnHeights[highestColumn] = @(columnHeight + footerHeight);
    }
    
    return attributes;
}

/**
 *  根据kind、indexPath，计算对应的LayoutAttributes
 */
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    
    //计算LayoutAttributes
    if([elementKind isEqualToString:kSupplementaryViewKindHeader]){
        CGFloat width = self.collectionView.bounds.size.width;
        CGFloat height = [self.delegate collectionViewLayout:self heightForSupplementaryHeaderViewAtIndexPath:indexPath];
        CGFloat x = 0;
        //根据offset计算kSupplementaryViewKindHeader的y
        //y = offset.y-(header高度-固定高度)
        CGFloat offsetY = self.collectionView.contentOffset.y;
        CGFloat y = MAX(0,
                        offsetY-(height-kSupplementaryViewKindHeaderPinnedHeight));
        attributes.frame = CGRectMake(x, y, width, height);
        attributes.zIndex = 1024;
    }
    else if ([elementKind isEqualToString:kSupplementaryViewKindFooter]) {
        CGFloat width = self.collectionView.bounds.size.width;
        CGFloat height = [self.delegate collectionViewLayout:self heightForSupplementaryFooterViewAtIndexPath:indexPath];
        CGFloat x = 0;
        //根据contentSize计算kSupplementaryViewKindFooter的y
        //y = offset.y-(footer高度-固定高度)
        CGFloat offsetY = self.collectionView.contentSize.height;
        CGFloat y = MAX(0,
                        offsetY-height);
        attributes.frame = CGRectMake(x, y, width, height);
        attributes.zIndex = 1024;
    }
    return attributes;
}


#pragma mark - helpers
/**
 *  找到高度最小的那一列的下标
 */
- (NSInteger)columnOfLessHeight
{
    if(self.columnHeights.count < 2){
        return 0;
    }

    __block NSInteger leastIndex = 0;
    [self.columnHeights enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        
        if([number floatValue] < [self.columnHeights[leastIndex] floatValue]){
            leastIndex = idx;
        }
    }];
    
    return leastIndex;
}

/**
 *  找到高度最大的那一列的下标
 */
- (NSInteger)columnOfMostHeight
{
    if(self.columnHeights.count < 2){
        return 0;
    }
    
    __block NSInteger mostIndex = 0;
    [self.columnHeights enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        
        if([number floatValue] > [self.columnHeights[mostIndex] floatValue]){
            mostIndex = idx;
        }
    }];
    
    return mostIndex;
}

#pragma mark - 根据rect返回应该出现的Items
/**
 *  计算目标rect中含有的item
 */
- (NSMutableArray<NSIndexPath *> *)indexPathForItemsInRect:(CGRect)rect
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    
    return indexPaths;
}

/**
 *  计算目标rect中含有的某类SupplementaryView
 */
- (NSMutableArray<NSIndexPath *> *)indexPathForSupplementaryViewsOfKind:(NSString *)kind InRect:(CGRect)rect
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    if([kind isEqualToString:kSupplementaryViewKindHeader]){
        //在这个瀑布流自定义布局中，只有一个位于列表顶部的SupplementaryView
        NSIndexPath *indexPath = self.headerIndexPath;
        
        //如果当前区域可以看到SupplementaryView，则返回
        //CGFloat height = [self.delegate collectionViewLayout:self heightForSupplementaryHeaderViewAtIndexPath:indexPath];
        //if(CGRectGetMinY(rect) <= height + _insets.top){
        //Header默认总是需要显示
        if (indexPath ){
            [indexPaths addObject:indexPath];
        }
        //}
    }
    else if ([kind isEqualToString:kSupplementaryViewKindFooter]) {
        
        NSIndexPath *indexPath = self.footerIndexPath;
        if (indexPath) {
            [indexPaths addObject:indexPath];
        }
    }
    
    return indexPaths;
}

@end
