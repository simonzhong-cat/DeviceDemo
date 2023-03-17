//
//  LWHomeCollectionView.m
//  LinWear
//
//  Created by lw on 2020/5/27.
//  Copyright © 2020 lw. All rights reserved.
//

#import "LWHomeCollectionView.h"
#import "LWHomeHeaderView.h" // 组头
#import "LWHomeFooterView.h" // 组尾

#import "LWHomeStepInfoCell.h" // 步数、卡路里、距离卡片
#import "LWHomeStepsInfoCell.h"
#import "LWAllSportsHistoryCell.h" // 运动记录卡片
#import "LWHomeWatchDialCell.h" // 表盘中心卡片
#import "LWHomeResetVersionCell.h" // 各个健康模块卡片

#import "LWMainHomeViewController.h"
#import "LWHomeCollectionModel.h"
#import "RLMHomeVisibleCardModel.h"

@interface LWHomeCollectionView () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, LWHomeStepsInfoCellDelegate, LWHomeFooterViewDelegate, LWHomeWatchDialCellDelegate, LWCollectionWaterfallLayoutProtocol>

@property (nonatomic, strong) NSArray <NSArray *> *itemDataArray;       // 支持的数据源

@end

static NSString *const headerViewIdty = @"LWHomeHeaderView";
static NSString *const footerViewIdty = @"LWHomeFooterView";
static NSString *const stepInfoIdty = @"LWHomeStepInfoCell";
static NSString *const stepsInfoIdty = @"LWHomeStepsInfoCell";
static NSString *const watchDialIdty = @"LWHomeWatchDialCell";
static NSString *const AllSportsHistoryIdty = @"LWAllSportsHistoryCell";
static NSString *const HomeResetVersionIdty = @"LWHomeResetVersionCell";

@implementation LWHomeCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(LWHomeWaterfallLayout *)layout {
    
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        
        self.delegate = self;
        self.dataSource = self;
        layout.delegate = self;
        
        self.backgroundColor = UIColor.clearColor;
        
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        
        // 天气
        [self registerClass:LWHomeHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerViewIdty];
        // 编辑卡片顺序
        [self registerClass:LWHomeFooterView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerViewIdty];
        
        // 步数、卡路里、距离
        [self registerClass:LWHomeStepInfoCell.class forCellWithReuseIdentifier:stepInfoIdty];
        [self registerClass:LWHomeStepsInfoCell.class forCellWithReuseIdentifier:stepsInfoIdty];
        // 全部运动记录
        [self registerNib:[UINib nibWithNibName:@"LWAllSportsHistoryCell" bundle:nil] forCellWithReuseIdentifier:AllSportsHistoryIdty];
        // 表盘中心
        [self registerClass:LWHomeWatchDialCell.class forCellWithReuseIdentifier:watchDialIdty];
        // 各个健康模块卡片
        [self registerClass:LWHomeResetVersionCell.class forCellWithReuseIdentifier:HomeResetVersionIdty];
        
        [LWHomeVisibleCardObject initializeCurrentCardListSort:NO];
    }
    return self;
}

#pragma mark - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return self.itemDataArray.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (section < self.itemDataArray.count) {
        return [self.itemDataArray[section] count];
    }
    return 0;
    
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = nil;
    
    LWHomeCollectionModel *model = nil;
    
    if (indexPath.section < self.itemDataArray.count) {
        
        NSArray *tempArr = self.itemDataArray[indexPath.section];
        
        if (indexPath.row < tempArr.count) {
            
            model = self.itemDataArray[indexPath.section][indexPath.row];
            
            if ([model.title isEqualToString:LWLocalizbleString(@"步数")]) {
                LWHomeStepsInfoCell *stepInfoCell = [collectionView dequeueReusableCellWithReuseIdentifier:stepsInfoIdty forIndexPath:indexPath];
                stepInfoCell.stepsInfoCellDelegate = self;
                stepInfoCell.homeDataCollectionModel = self.homeDataCollectionModel;
                cell = stepInfoCell;
            }
            
            else if ([model.title isEqualToString:LWLocalizbleString(@"全部运动记录")]) {
                LWAllSportsHistoryCell *sportsHistoryCell = [collectionView dequeueReusableCellWithReuseIdentifier:AllSportsHistoryIdty forIndexPath:indexPath];
                [sportsHistoryCell reloadLastSportCell:self.homeDataCollectionModel];
                cell = sportsHistoryCell;
            }
            
            else if ([model.title isEqualToString:LWLocalizbleString(@"表盘")]) {
                LWHomeWatchDialCell *homeWatchDialCell = [collectionView dequeueReusableCellWithReuseIdentifier:watchDialIdty forIndexPath:indexPath];
                homeWatchDialCell.dialArrayData = self.homeDataCollectionModel.dialArrayData;
                homeWatchDialCell.delegate = self;
                cell = homeWatchDialCell;
            }
            
            else {
                LWHomeResetVersionCell *HomeResetVersionCell = [collectionView dequeueReusableCellWithReuseIdentifier:HomeResetVersionIdty forIndexPath:indexPath];
                CGFloat itemHigh = [HomeResetVersionCell reloadCellTitle:model.title withModel:self.homeDataCollectionModel];
                model.itemHeight = itemHigh;
                cell = HomeResetVersionCell;
            }
        }
        
    }
    
    cell.layer.backgroundColor = LWCustomColor.whiteColor.CGColor;
    cell.layer.cornerRadius = 16;
    
    return cell;
}

// 组的头尾视图
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        LWHomeHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:headerViewIdty forIndexPath:indexPath];
        
        return headerView;
    }
    
    else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        // 编辑卡片顺序
        LWHomeFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:footerViewIdty forIndexPath:indexPath];
        footerView.delegate = self;

        return footerView;
    }
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    
    LWHomeCollectionModel *model = self.itemDataArray[indexPath.section][indexPath.row];
    NSString *cellTitle = model.title;
    
    NSInteger begin = 0;
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"全部运动记录")]) {
        begin = self.homeDataCollectionModel.lastSports.begin;
        LWLog(@"【首页】点击了【全部运动记录】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        [vc pushLWMotionViewControllerWithTime:begin];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"心率")]) {
        begin = self.homeDataCollectionModel.heartRateTimestamp;
        LWLog(@"【首页】点击了【心率】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        [vc pushLWHeaderRateViewControllerWithTime:begin];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"睡眠")]) {
        NSInteger sleepEnd = 0;
        NSInteger NapEnd = 0;
        if (self.homeDataCollectionModel.sleepEndTimestamp) {
            sleepEnd = self.homeDataCollectionModel.sleepEndTimestamp.timeIntervalSince1970;
        }
        if (self.homeDataCollectionModel.sporadicNapEndTimestamp) {
            NapEnd = self.homeDataCollectionModel.sporadicNapEndTimestamp.timeIntervalSince1970;
        }
        begin = sleepEnd>NapEnd ? sleepEnd : NapEnd;
        NSInteger recentSleepTimestamp = self.homeDataCollectionModel.recentSleepTimestamp;
        LWLog(@"【首页】点击了【睡眠】最新数据时间戳: %ld (%@), 对应是 %ld (%@) 这天的睡眠", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin], recentSleepTimestamp, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:recentSleepTimestamp]);
        [vc pushLWSleepViewControllerWithTime:recentSleepTimestamp];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"体重")]) {
        begin = self.homeDataCollectionModel.weightTimestamp;
        LWLog(@"【首页】点击了【体重】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        // 需求改动：首页点击进入体重详情，改成今天展示
        [vc pushLWBodyWeightViewControllerWithTime:NSDate.getNowTimeInterval];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"血氧")]) {
        begin = self.homeDataCollectionModel.bloodOxygenTimestamp;
        LWLog(@"【首页】点击了【血氧】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        [vc pushLWBloodOxygenViewControllerWithTime:begin];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"血压")]) {
        begin = self.homeDataCollectionModel.bloodPressureTimestamp;
        LWLog(@"【首页】点击了【血压】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        [vc pushLWBloodPressureViewControllerWithTime:begin];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"生理周期")]) {
        [vc pushLWWomenHealthViewControllers];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"体温")]) {
        begin = self.homeDataCollectionModel.bodyTemperatureTimestamp;
        LWLog(@"【首页】点击了【体温】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        // 需求改动：首页点击进入体温详情，改成今天展示
        [vc pushLWBodyTemperatureViewControllerWithTime:NSDate.getNowTimeInterval];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"压力")]) {
        begin = self.homeDataCollectionModel.stressTimestamp;
        LWLog(@"【首页】点击了【压力】最新数据时间戳: %ld (%@)", begin, [NSDate dateYYYYMMDDHHMMSSByTimeStamp:begin]);
        [vc pushLWStressViewControllerWithTime:begin];
    }
    
    if ([cellTitle isEqualToString: LWLocalizbleString(@"全部健康数据")]) {
        [vc pushLWHiddenHomeHealthDataCardViewController];
    }
}

#pragma mark - CollectionWaterfallLayoutProtocol
// cell高度
- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LWHomeCollectionModel *model = self.itemDataArray[indexPath.section][indexPath.row];
    return model.itemHeight;
}

// 组头高度
- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForSupplementaryHeaderViewAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 && indexPath.row == 0){
        return 86;
    }
    return 0;
}

// 组尾高度
- (CGFloat)collectionViewLayout:(LWHomeWaterfallLayout *)layout heightForSupplementaryFooterViewAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *array = self.itemDataArray[indexPath.section];
    if(indexPath.section == 1 && indexPath.row == array.count-1) { // 当第二组有值时，第二组最后一个的位置
        return 60+18;
    } else if (indexPath.section+1 < self.itemDataArray.count) {
        NSArray *section_Array = self.itemDataArray[indexPath.section];
        NSArray *section2_Array = self.itemDataArray[indexPath.section+1];
        if (!section2_Array.count && indexPath.row == section_Array.count-1) { // 当第二组没有值时，第一组最后一个的位置
            return 60+18;
        }
    }
    return 0;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([self.customDelegate respondsToSelector:@selector(customScrollViewDidScroll:)]) {
        [self.customDelegate customScrollViewDidScroll:scrollView];
    }
}

#pragma mark - LWHomeStepInfoCellDelegate
- (void)selectedStepButtonAction {
    LWLog(@"点击了步数");
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    [vc pushLWStepViewController];
}

- (void)selectedCalorieButtonAction {
    LWLog(@"点击了卡路里");
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    [vc pushLWCalorieViewController];
}

- (void)selectedDistanceButtonAction {
    LWLog(@"点击了距离");
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    [vc pushLWDistanceViewController];
}

#pragma mark - LWHomeWatchDialCellDelegate 表盘卡片代理:更多表盘 / 点击单个表盘
- (void)selecteMoreDialAction {
    LWLog(@"点击了更多表盘");
    if (![LWDeviceRequestManager getCurrentDeviceConnectStasus]) {
        [JHUDManager showText:LWLocalizbleString(@"您还没有连接设备") addToView:self];
        return;
    }
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    [vc pushLWDialTopViewController];
}

- (void)selecteCurrentDialBeginSyncWatch:(LWMinePlateModel *)dialModel {
    LWLog(@"进入表盘详情页");
    if (![LWDeviceRequestManager getCurrentDeviceConnectStasus]) {
        [JHUDManager showText:LWLocalizbleString(@"您还没有连接设备") addToView:self];
        return;
    }
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    LWLog(@"用户选中的表盘缩略图是 %@\n用户选中的表盘名称是 %@\n用户选中的表盘文件是 %@", dialModel.plateUrl, dialModel.plateName, dialModel.plateZip);
    [vc pushLWDialManagementVC:dialModel];
}

#pragma mark - LWHomeFooterViewDelegate 全部健康数据
- (void)selectedEditCardAction {
    LWLog(@"点击了编辑卡片");
    LWMainHomeViewController *vc = (LWMainHomeViewController *)self.viewController;
    [vc pushLWHiddenHomeHealthDataCardViewController];
}


#pragma mark - 数据源处理
- (void)reloadCollectionViewData {
    
    /** 所有的数据源 */
    // 第一组 - - - 1列
    NSMutableArray *array1 = NSMutableArray.array;
    
    LWHomeCollectionModel *model1 = LWHomeCollectionModel.new;
    model1.title = LWLocalizbleString(@"步数");
    model1.itemHeight = 222;
    [array1 addObject:model1];
    
    if (IsHaveGPS_Motion) {
        LWHomeCollectionModel *model2 = LWHomeCollectionModel.new;
        model2.title = LWLocalizbleString(@"全部运动记录");
        model2.itemHeight = 148;
        [array1 addObject:model2];
    }
    
    LWHomeCollectionModel *model3 = LWHomeCollectionModel.new;
    model3.title = LWLocalizbleString(@"表盘");
    model3.itemHeight = 148;
    [array1 addObject:model3];
    
    
    // 第二组 - - - 2列
    __block NSMutableArray *array2 = NSMutableArray.array;
    
    WeakSelf(self);
    [LWHomeVisibleCardObject getCurrentCardListSortWithBlock:^(NSArray<LWHomeCollectionModel *> * _Nonnull showGroup, NSArray<LWHomeCollectionModel *> * _Nonnull hideGroup) {
        
        // 筛选符合条件的元素
        // 将筛选逻辑放到一个 NSPredicate 中，以便使用 filteredArrayUsingPredicate: 方法筛选出符合条件的元素。这样可以减少循环的次数。
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(LWHomeCollectionModel *obj, NSDictionary *bindings) {
            switch (obj.healthDataType) {
                    // 女性健康根据配置展示
                case LWHealthDataTypeWomenHealth:
                    return LWDeviceRequestManager.allowFemaleHealth;
                    
                    // 其它都允许展示（即使配置表不支持此功能）
                    // 在展示查询数据的时候根据配置表【是否支持】来查询
                default:
                    return YES;
            }
        }];
        
        // 添加符合条件的元素到 array2
        NSArray *filteredArray = [showGroup filteredArrayUsingPredicate:predicate];
        [array2 addObjectsFromArray:filteredArray];
        
        for (LWHomeCollectionModel *model in array2) {
            LWLog(@"【首页】当前卡片列表 实际排序 %@", model.title);
        }
        
        // 数据源
        weakSelf.itemDataArray = @[array1, array2];
        
        GCD_MAIN_QUEUE(^{
            // 刷新列表
            [weakSelf reloadData];
            [weakSelf setContentOffset:CGPointMake(weakSelf.contentOffset.x, weakSelf.contentOffset.y-1) animated:YES]; // 强制滚动一下强制计算刷新layout
        });
    }];
}

@end
