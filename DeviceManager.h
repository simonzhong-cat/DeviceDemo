//
//  UTEBLEDeviceManager.h
//  LinWear
//
//  Created by Simon on 2022/12/8.
//  Copyright © 2022 lw. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UTEBLEDeviceManager : NSObject


#pragma mark - 【GET】获取设备基本信息
/// 获取设备基本信息（名称，Mac地址，项目号，电量，是否初始化，是否已连接）
+ (void)requestUTEDeviceConfig:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】查找设备
/// 查找设备
+ (void)requestFindDevice:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】恢复出厂设置
/// 恢复出厂设置
+ (void)requestReset:(void(^)(id result))success
             failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取手表电量
///  获取手表电量
+ (void)getBatteryInfo:(void(^)(id result))success
               failure:(void(^)(NSError *error))failure;


#pragma mark - 【SET】同步系统时间（将手表的时间同步成跟手机的系统时间一致）
/// 同步系统时间（将手表的时间同步成跟手机的系统时间一致）
+ (void)setDeviceSystemTime:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】同步天气
/// 同步天气
+ (void)requestSetWeather:(NSDictionary *)param
                  success:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置手表偏好 (时间和单位)
/// 设置手表偏好 (时间和单位)
+ (void)requestSetUTEPrefer:(NSDictionary *)param
                    success:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取用户个人信息
/// 获取用户个人信息
+ (void)requestUTEUserProfile:(void(^)(id result))success
                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置用户个人信息
/// 设置用户个人信息
+ (void)setUTEUserProfile:(NSDictionary *)param
                  success:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure;

#pragma mark - 女性健康设置
///  女性健康设置
+ (void)setUTEWomenHealthConfig:(NSDictionary *)param
                            success:(void(^)(id result))success
                            failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】即时拍照
/// 即时拍照
+ (void)setUTEInstantPhotoStatus:(NSDictionary *)param
                      success:(void(^)(id result))success
                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置通知开关
/// 设置通知开关
+ (void)setUTEMessageNotification:(LWDeviceMessageNoticeModel *)setting
                       success:(void(^)(id result))success
                       failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】设置通知开关
/// 设置通知开关
+ (void)requestUTEMessageNotification:(void(^)(id result))success
                       failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取久坐提醒设置
/// 获取久坐提醒设置
+ (void)requestUTERemindTime:(void(^)(id result))success
                     failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置久坐提醒
/// 设置久坐提醒
+ (void)setSedentaryRemind:(NSDictionary *)param
                   success:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取喝水提醒设置
/// 获取喝水提醒
+ (void)requestUTEDrinkRemindSetting:(void(^)(id result))success
                          failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置喝水提醒
/// 设置喝水提醒
+ (void)setUTEDrinkRemind:(NSDictionary *)param
               success:(void(^)(id result))success
               failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取勿扰模式设置
/// 获取勿扰模式设置
+ (void)requestUTEDoNotDisturbSetting:(void(^)(id result))success
                              failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】勿扰模式设置
/// 设置勿扰模式
+ (void)setUTEDoNotDisturbSetting:(NSDictionary *)param
                          success:(void(^)(id result))success
                          failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取抬腕亮屏设置
/// 获取抬腕亮屏设置
+ (void)requestUTEWristWakeUpSetting:(void(^)(id result))success
                             failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】抬腕亮屏设置
/// 设置抬腕亮屏
+ (void)setUTEWristWakeUpSetting:(NSDictionary *)param
                         success:(void(^)(id result))success
                         failure:(void(^)(NSError *error))failure;

//#pragma mark - 【GET】获取抬腕亮屏时长
///// 获取抬腕亮屏时长
//+ (void)requestUTEDurationOfBrightScreen:(void(^)(id result))success
//                              failure:(void(^)(NSError *error))failure;
//
//#pragma mark - 【SET】设置抬腕亮屏时长
///// 设置抬腕亮屏时长
//+ (void)setUTEDurationOfBrightScreen:(NSDictionary *)param
//                             success:(void(^)(id result))success
//                             failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取健康定时监测
/// 获取健康定时监测设置
+ (void)requestUTEHealthTimingMonitor:(void(^)(id result))success
                              failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置健康定时监测
/// 设置健康定时监测
+ (void)setUTEHealthTimingMonitor:(NSDictionary *)param
                       success:(void(^)(id result))success
                       failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取心率上限预警
/// 获取心率上限预警
+ (void)getHeartRateWarning:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置心率上限预警
/// 设置心率上线预警
+ (void)setHeartRateWarning:(NSDictionary *)param
                    success:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取闹钟
/// 获取闹钟设置
+ (void)getAlarmUTEClockBlock:(void(^)(id result))success
                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置闹钟
/// 设置闹钟
+ (void)setAlarmUTEAddClock:(NSDictionary *)param
                   succcess:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】删除闹钟
/// 删除闹钟
+ (void)deleteUTEAlarm:(NSDictionary *)param
                      success:(void (^)(id _Nonnull))success
                      failure:(void (^)(NSError * _Nonnull))failure;

#pragma mark - 【SET】编辑闹钟
/// 修改闹钟
+ (void)editorUTEAlarm:(NSDictionary *)param
                   success:(void (^)(id _Nonnull))success
               failure:(void (^)(NSError * _Nonnull))failure;

#pragma mark - 设置目标提醒
/// 设置目标提醒
+ (void)setUTEGoalReminder:(NSDictionary *)param
                   success:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取消息通知设置
/// 获取消息通知设置
+ (void)requestUTEMessageNotificationReminder:(void(^)(id result))success
                                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置消息通知
/// 设置消息通知
+ (void)setUTEMessageNotificationReminder:(LWDeviceMessageNoticeModel *)setting
                                      success:(void(^)(id result))success
                                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取常用联系人
/// 获取常用联系人
+ (void)getUTEFavContactsList:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】设置常用联系人列表
/// 设置常用联系人列表
+ (void)setUTEFavoriteContactsList:(NSArray *)param
                        success:(void(^)(id result))success
                        failure:(void(^)(NSError *error))failure;


#pragma mark - 表盘相关
/// 获取当前手表的配置
+ (void)requestGetUTEDialInfo:(void(^)(UTEModelDeviceDisplayModel *localDisplayModel))success
                      failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取UTE设备支持的运动
/// 获取UTE设备支持的运动
- (void)readUTESportModelSupportWithBlock:(void(^)(NSInteger minDisplay, NSInteger maxDisplay, NSArray<NSNumber *> * _Nullable array))success
                                  failure:(void(^)(NSError *error))failure;

#pragma mark - 【GET】获取UTE设备当前显示的运动
/// 获取UTE设备当前显示的运动
- (void)readUTESportModelCurrentDisplayWithBlock:(void(^)(NSArray<NSNumber *> * _Nullable array))success
                                  failure:(void(^)(NSError *error))failure;

#pragma mark - 【SET】更改UTE设备当前显示的运动
/// 更改UTE设备当前显示的运动
- (void)setUTESportModelCurrentDisplay:(LWSportType)sportType
                               success:(void(^)(id result))success
                               failure:(void(^)(NSError *error))failure;

#pragma mark - UTE设备GPS运动状态控制
/// UTE设备GPS运动状态控制
- (void)setUTESportModel:(LWGPSMotionTempModel *)model
                 success:(void(^)(id result))success
                 failure:(void(^)(NSError *error))failure;

#pragma mark - UTE设备GPS运动数据交流
///UTE设备GPS运动数据交流
- (void)setUTESportModelInfo:(LWGPSMotionTempModel *)model
                     success:(void(^)(id result))success
                     failure:(void(^)(NSError *error))failure;

#pragma mark - 将 UTE SDK 返回的运动 Code 转换成 LinWear 自己维护的运动 Code
/// 将 UTE SDK 返回的运动 Code 转换成 LinWear 自己维护的运动 Code
- (NSInteger)UTESportCodeConversionToLinWearSportCode:(NSInteger)type;

#pragma mark - 【GET】手动同步历史运动健康数据
/// 手动同步历史运动健康数据
+ (void)requestUTEHistorySportsHealthData:(void(^)(CGFloat progress, NSString *tip))progressBlcok
                               success:(void(^)(id result))success
                               failure:(void(^)(NSError *error))failure;



@end

NS_ASSUME_NONNULL_END
