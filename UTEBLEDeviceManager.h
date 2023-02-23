//
//  UTEBLEDeviceManager.h
//  LinWear
//
//  Created by Simon on 2022/12/8.
//  Copyright © 2022 lw. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UTEBLEDeviceManagerDelegate <NSObject>

@optional
/// 启动扫描设备
- (void)ute_deviceManagerStartScanDevice;

/// 扫描到的设备
- (void)ute_deviceManagerScaning:(UTEModelDevices *)deviceInfo RSSI:(NSNumber *)RSSI name:(NSString *)name mac:(NSString *)mac adapter:(NSString *)adapter;

/// 蓝牙状态
- (void)ute_deviceManagerBluethoothDidUpdateState:(UTEBluetoothState)central;

/// 正在连接设备
- (void)ute_deviceManagerInConnectingPeripheral:(UTEModelDevices *)deviceInfo;

/// 设备已断开连接
- (void)ute_deviceManagerDidDisconnectPeripheral:(UTEModelDevices *)deviceInfo;

/// 连接设备失败
- (void)ute_deviceManagerConnectPeripheralFailed:(UTEModelDevices *)deviceInfo;

/// 连接设备成功
- (void)ute_deviceManagerConnectPeripheralSucceed:(UTEModelDevices *)deviceInfo isFirstConnected:(BOOL)isFirstConnected;

/// 手表通知App,手表进入了拍照模式
- (void)ute_deviceManagerEnterCameraMode;

/// 手表通知App,手表发出了拍照指令
- (void)ute_deviceManagerTakePicture;

/// 手表通知App,手表退出了拍照模式
- (void)ute_deviceManagerExitCameraMode;

/// 手表设备按键事件(或触摸反馈)
///  *  e.g. 'data' is <D10A> ,2 bytes, Indicates that the device has been clicked (or touched) (find iPhone)
///  *  e.g. 'data' is <D10A0100> ,4 bytes, Indicates that the device has been clicked again (or touched again) (stop find iPhone)
- (void)ute_deviceManageTouchDeviceReceiveData:(NSData *)data;

/// SDK向设备发送命令 如果设备接收到值，此方法将有回调。
- (void)ute_deviceManagerReceiveCustomData:(NSData *)data result:(BOOL)result;

/// 实时读取手表上的操作的快捷开关状态
- (void)ute_deviceManagerShortcutBtnStatus:(UTEDeviceShortcutBtnType)openType closeType:(UTEDeviceShortcutBtnType)closeType;

/// 获取手表上支持的快捷开关
- (void)ute_deviceManagerShortcutBtnSupportModel:(UTEModelShortcutBtn *)model;

/// 读取手表上的操作的快捷开关状态
- (void)ute_deviceManagerShortcutBtnStatusModel:(UTEModelShortcutBtn *)model;

@end

typedef void(^UTE_SubscriptionHistoryDataBlock)(id result); // 订阅数据返回block。用于数据返回时刷新首页

@interface UTEBLEDeviceManager : NSObject<UTEManagerDelegate>

@property (nonatomic, copy) UTE_SubscriptionHistoryDataBlock subscriptionHistoryDataBlock;

/// 实例化
+ (instancetype)defaultManager;

/// 由于SDK部分协议没有指令回调，指令发送前检查下，error不为nil则认为发送成功
+ (NSError *)sendingFailed;

/// 委托代理
@property (nonatomic, weak) id<UTEBLEDeviceManagerDelegate> delegate;

/// 外设
@property (strong, nonatomic, nullable) UTEModelDevices *deviceInfo;

/// 设备名称
@property (copy, nonatomic, nullable) NSString *deviceName;

/// 是否初始化成功，YES即准备就绪可以通讯交互
@property (nonatomic, assign) BOOL isReady;

/// 是否首次连接,非首次连接,回连的配置信息需要走上次设置的配置
@property (nonatomic, assign) BOOL isFirstConnected;

/// 电池电量，连接成功时获取一次
@property (nonatomic, assign) NSInteger batteryLevel;

#pragma mark - 开始搜索设备
/// 开始搜索设备
- (void)scanBLEPeripherals;

#pragma mark - 停止搜索设备
/// 停止搜索设备
- (void)stopScanBLEPeripherals;

#pragma mark - 清除绑定记录并且断开设备
/// 清除绑定记录并且断开设备
- (void)requestUTEClearPeripheralHistory;

#pragma mark - 连接设备
/// 连接设备
- (void)connectPeripheral:(UTEModelDevices *)deviceInfo;

#pragma mark - 解绑设备
/// 解绑设备
+ (void)requestUnbindUTEDevice:(void(^)(id result))success
                       failure:(void(^)(NSError *error))failure;

#pragma mark - 断开当前连接设备
/// 断开当前连接设备
- (void)disconnectCurrentPeripheral;

#pragma mark - 尝试连接最后连接的外部设备
/// 尝试连接最后连接的外部设备
+ (void)tryConnect;


#pragma mark - 是否包含快速眼动
// 是否包含快速眼动
+ (BOOL)allowHaveRapidEyeMovemen;

#pragma mark - 获取手表支持哪些快捷开关 isHasShortcutButton = YES
/// 获取手表支持哪些快捷开关 isHasShortcutButton = YES
/// 回调结果在 delegate 的 ute_deviceManagerShortcutBtnSupportModel: 方法读取
+ (BOOL)readDeviceShortcutBtnSupport;

#pragma mark - 获取手表支持的快捷开关状态 isHasShortcutButton = YES
/// 获取手表支持的快捷开关状态 isHasShortcutButton = YES
/// 回调结果在 delegate 的 ute_deviceManagerShortcutBtnStatusModel: 方法读取
+ (BOOL)readDeviceShortcutBtnStatus;

#pragma mark - 获取手表内部的版本号码 UTE内部的版本类似 1.0.0 这种 [UTESmartBandClient sharedInstance].isCustomDataSending = YES
/// 获取手表内部的版本号码 UTE内部的版本类似 1.0.0 这种
/// 回调结果 在 delegate 的 ute_deviceManagerReceiveCustomData: 方法读取
+ (BOOL)readDeviceInfoPrivateVersion;

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
