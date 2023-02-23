//
//  UTEBLEDeviceManager.m
//  LinWear
//
//  Created by Simon on 2022/12/8.
//  Copyright © 2022 lw. All rights reserved.
//

#import "UTEBLEDeviceManager.h"
#import "RLMUTEPrivates.h"
#import "RLMStepModel.h"
#import "RLMSleepModel.h"
#import "RLMHeartRateModel.h"
#import "RLMBloodOxygenModel.h"
#import "RLMSportsModel.h"
#import "RLMManualTestModel.h"

#import "LWPersonModel.h"

#import "LWMainHomeViewController.h"

#define UTESERVICEID_1 @"5535"
#define UTESERVICEID_2 @"2222"
#define UTESERVICEID_3 @"5536"
#define UTESCANTIMEOUT  30.0f         // 搜索超时时间设定

@interface UTEBLEDeviceManager()


@end

@implementation UTEBLEDeviceManager



#pragma mark - 【GET】获取设备配置信息
+ (void)requestUTEDeviceConfig:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure {
    
    NSDictionary *responseObject = [[NSUserDefaults standardUserDefaults] objectForKey:LW_DEVICE_INFO];
    
    if (responseObject.count) {
        
        NSString *name = IF_NULL_TO_STRING(responseObject[@"name"]); // 设备名称
        NSString *mac = IF_NULL_TO_STRING(responseObject[@"mac"]); // mac地址
        NSString *firmwareVersion = IF_NULL_TO_STRING(responseObject[@"firmwareVersion"]); // 固件版本号
        NSString *projectNo = IF_NULL_TO_STRING(responseObject[@"projectNo"]); // 项目的编号
        BOOL deviceReady = [UTESmartBandClient sharedInstance].connectedDevicesModel.isConnected; // sdk是否初始化完成
        NSInteger percent = [UTESmartBandClient sharedInstance].connectedDevicesModel.battery; // 电量百分比  范围：0～100
        NSInteger batteryState = 0; // 手表充电状态  0 未充电  1 充电中
        
        NSDictionary *result = @{@"name" : name,
                                 @"macAddress" : mac,
                                 @"firmwareVersion" : firmwareVersion,
                                 @"projectNo" : projectNo,
                                 @"connected" : @(deviceReady),
                                 @"deviceReady" : @(deviceReady),
                                 @"percent" : @(percent),
                                 @"batteryState" : @(batteryState)
        };
        if (success) {
            success(result);
        }
    }
}

#pragma mark - 【GET】查找设备
/// 查找设备
+ (void)requestFindDevice:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure {
    
    BOOL sendCommandStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionFindBand];
    LWLog(@"【UTE】*** 查找手表指令发送 %@", sendCommandStatus ? @"成功" : @"失败");
    if (sendCommandStatus) {
        if (success) {
            success(@(YES));
        }
    } else {
//        if (failure) {
//            failure(error);
//        }
    }
}

#pragma mark - 【SET】恢复出厂设置
/// 恢复出厂设置
+ (void)requestReset:(void(^)(id result))success
             failure:(void(^)(NSError *error))failure {
    
    BOOL sendCommandStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionDeleteDevicesAllData];
    LWLog(@"【UTE】*** 恢复手表出厂设置指令发送 %@", sendCommandStatus ? @"成功" : @"失败");
    if (sendCommandStatus) {
        if (success) {
            success(@(YES));
        }
    } else {
//        if (failure) {
//            failure(error);
//        }
    }
}

#pragma mark -【GET】获取手表电量
///  获取手表电量
+ (void)getBatteryInfo:(void(^)(id result))success
               failure:(void(^)(NSError *error))failure {
    
    if (![UTESmartBandClient sharedInstance].connectedDevicesModel.isConnected) {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:100 userInfo:@{@"message":LWLocalizbleString(@"您还没有连接设备")}];
        failure(error);
        return;
    }
    
    NSInteger batteryPercent = [UTESmartBandClient sharedInstance].connectedDevicesModel.battery;//电量百分比
    // UTE 没有获取手表充电状态的接口
    NSDictionary *result = @{@"batteryState" : @(0),
                             @"batteryValue" : @(0),
                             @"batteryPercent" : @(batteryPercent)
    };
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】同步系统时间（将手表的时间同步成跟手机的系统时间一致）
// 同步系统时间（将手表的时间同步成跟手机的系统时间一致）
+ (void)setDeviceSystemTime:(void(^)(id result))success
                      failure:(void(^)(NSError *error))failure {
    
    BOOL sendCommandStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionSyncTime];
    LWLog(@"【UTE】*** 设备同步系统时间指令发送 %@", sendCommandStatus ? @"成功" : @"失败");
    
    if (sendCommandStatus) {
        if (success) {
            success(@(YES));
        }
    } else {
//        if (failure) {
//            failure(error);
//        }
    }
}

#pragma mark - 【SET】同步天气
/// 同步天气
+ (void)requestSetWeather:(NSDictionary *)param
                  success:(void(^)(id result))success
                  failure:(void(^)(NSError *error))failure {
    
    
    NSDictionary *currentWeatherDict = param[@"current"];
    NSInteger weathertype = [currentWeatherDict[@"code"] integerValue];
    UTEWeatherType uteWeatherType = [self returnWeatherForCode:weathertype];
    
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasWeatherSeven) {
        LWLog(@"【UTE】*** 当前设备支持七天天气数据");
        
        NSArray *forecastWeatherDataArr = param[@"forecast"];
        
        NSMutableArray *forecastWeatherArr = @[].mutableCopy;
        
        for (int i = 0; i < forecastWeatherDataArr.count; i++) {
            UTEModelWeather *weatherModel = UTEModelWeather.new;
            weatherModel.type = [self returnWeatherForCode:[forecastWeatherDataArr[i][@"code"] integerValue]];
            weatherModel.temperatureCurrent = [forecastWeatherDataArr[i][@"temperature"] integerValue];
            weatherModel.temperatureMax = [forecastWeatherDataArr[i][@"temp_high"] integerValue];
            weatherModel.temperatureMin = [forecastWeatherDataArr[i][@"temp_low"] integerValue];
            [forecastWeatherArr addObject:weatherModel];
        }
        
        BOOL sendCommandStatus = [[UTESmartBandClient sharedInstance] sendUTESevenWeather:forecastWeatherArr];
        LWLog(@"【UTE】*** 设备同步七天天气数据指令发送 %@ (未来天气数据数组 %@ 0)", sendCommandStatus ? @"成功" : @"失败", forecastWeatherDataArr.count ? @">" : @"=");
        
        if (sendCommandStatus) {
            if (success) {
                success(@(YES));
            }
        } else {
    //        if (failure) {
    //            failure(error);
    //        }
        }
    }
    
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasWeather) {
        LWLog(@"【UTE】*** 当前设备支持两天天气数据");
        BOOL sendCommandStatus = [[UTESmartBandClient sharedInstance] sendUTETodayWeather:uteWeatherType
                                                     currentTemp:[currentWeatherDict[@"temperature"] integerValue]
                                                         maxTemp:[currentWeatherDict[@"temp_high"] integerValue]
                                                         minTemp:[currentWeatherDict[@"temp_low"] integerValue]
                                                            pm25:0
                                                             aqi:0
                                                    tomorrowType:uteWeatherType
                                                          tmrMax:[currentWeatherDict[@"temp_high"] integerValue]
                                                          tmrMin:[currentWeatherDict[@"temp_low"] integerValue]];
        LWLog(@"【UTE】*** 设备同步两天天气数据指令发送 %@", sendCommandStatus ? @"成功" : @"失败");
        
        if (sendCommandStatus) {
            if (success) {
                success(@(YES));
            }
        } else {
    //        if (failure) {
    //            failure(error);
    //        }
        }
    }
}

+ (UTEWeatherType)returnWeatherForCode:(NSInteger)code {
    
    switch (code) {
        case 1:
            return UTEWeatherTypeSunny;
            break;
            
        case 2: // 多云
            return UTEWeatherTypeCloudy;
            break;
            
        case 3:// 阴天
            return UTEWeatherTypeOvercast;
            break;
            
        case 4:// 阵雨
            return UTEWeatherTypeShower;
            break;
            
        case 5:// 雷阵雨、雷阵雨伴有冰雹
            return UTEWeatherTypeThunderStorm;
            break;
            
        case 6: // 小雨
            return UTEWeatherTypeLightRain;
            break;
            
        case 7:  // 中雨(moderate rain)、大雨(heavy rain)、暴雨(rainstorm)
        case 8:
        case 9:
            return UTEWeatherTypePouring;
            break;
            
        case 10:// 雨夹雪、冻雨
            return UTEWeatherTypeSnow;
            break;
            
        case 11: // 小雪
            return UTEWeatherTypeSnow;
            break;
            
        case 12:// 大雪、暴雪
        case 13:
            return UTEWeatherTypeSnow;
            break;
            
        case 14: // 沙尘暴、浮沉
            return UTEWeatherTypeSandstorm;
            break;
            
        case 15:// 雾、雾霾
            return UTEWeatherTypeMistHaze;
            break;
            
        default:
            return UTEWeatherTypeSunny;
            break;
    }
}

#pragma mark - 【SET】设置手表偏好 (时间和单位)
+ (void)requestSetUTEPrefer:(NSDictionary *)param
                    success:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure {
    
    
    BOOL is12TimeFormat = [param[@"is12Hour"] boolValue];
    BOOL isImperialUnit = [param[@"isImperialUnit"] boolValue];
    
    BOOL syncUnitStatus;
    
    if (isImperialUnit) {
        
        if (is12TimeFormat) {
            syncUnitStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionUnitInch_12]; // 单位为英制和磅（lbs）、12小时（上午、下午）
            LWLog(@"【UTE】*** 单位为英制和磅（lbs）、时间格式12小时（上午、下午）设置 %@", syncUnitStatus ? @"成功" : @"失败");
        } else {
            syncUnitStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionUnitInch_24]; // 单位为英制和磅（lbs）、24小时制
            LWLog(@"【UTE】*** 单位为英制和磅（lbs）、时间格式24小时制 设置 %@", syncUnitStatus ? @"成功" : @"失败");
        }
        
    } else {
        
        if (is12TimeFormat) {
            syncUnitStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionUnitMeter_12]; // 单位为公制和千克、12小时（上午、下午）
            LWLog(@"【UTE】*** 单位为公制和千克、时间格式12小时（上午、下午）设置 %@", syncUnitStatus ? @"成功" : @"失败");
        } else {
            syncUnitStatus = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionUnitMeter_24]; // 单位为公制和千克、24小时制
            LWLog(@"【UTE】*** 单位为公制和千克、时间格式24小时制 设置 %@", syncUnitStatus ? @"成功" : @"失败");
        }
    }
    
    if (syncUnitStatus) {
        if (success) {
            success(@(YES));
        }
    } else {
//        if (failure) {
//            failure(error);
//        }
    }
}

#pragma mark - 【GET】获取用户个人信息
/// 获取用户个人信息
+ (void)requestUTEUserProfile:(void(^)(id result))success
                     failure:(void(^)(NSError *error))failure {
    
    RLMUTEUserInfoModel *model = [RLMUTEUserInfoModel.allObjects lastObject];
    if (model) {
        
    } else {
        // 兼容旧版本
    }
}

#pragma mark - 【SET】设置用户个人信息
/** 设置用户个人信息*/
+ (void)setUTEUserProfile:(NSDictionary *)param
                         success:(void(^)(id result))success
                         failure:(void(^)(NSError *error))failure {
    
    NSInteger age = [param[@"age"] integerValue];
    NSInteger gender = [param[@"gender"] integerValue];
    
    UTEModelDeviceInfo *infoModel = [[UTEModelDeviceInfo alloc] init];
    
    RLMUTEUserInfoModel *model = [RLMUTEUserInfoModel.allObjects lastObject];
    if (model && (param == nil)) {

        // 设置身高
        infoModel.heigh = LWUserInfoManager.getUserInfo.height;
        // 设置体重
        infoModel.weight = LWUserInfoManager.getUserInfo.weight;
        // 运动目标
        infoModel.sportTarget = LWUserInfoManager.getUserInfo.stepGoal;
        // 设置抬腕亮屏
        infoModel.handlight = model.wristwakeModel.on;
        // 手表亮屏时间(秒)
        infoModel.lightTime = model.wristwakeModel.interval;
        // 设置年龄
        infoModel.age = age;
        // 设置性别
        infoModel.sex = gender == 2 ? UTEDeviceInfoSexFemale : UTEDeviceInfoSexMale;
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasMaxHeartAlert) {
            // 设置心率预警
            infoModel.maxHeart = model.healthTimingModel.waringON == NO ? -1 : model.healthTimingModel.maxValue;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasMinHeartAlert) {
            infoModel.minHeart = model.healthTimingModel.minValue;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSleepAux) {
            infoModel.sleepAux = model.sleepAux;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSmartLost) {
            infoModel.isSmartLost = model.isSmartLost;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSwitchCH_EN) {
            infoModel.languageIsChinese = model.languageIsChinese;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSwitchTempUnit) {
            // 设置温度单位
            infoModel.isFahrenheit = model.isFahrenheit;
        }
        
        // 是否设置成功
        BOOL status = [[UTESmartBandClient sharedInstance] setUTEInfoModel:infoModel];
        
        NSString *sexStr = infoModel.sex == UTEDeviceInfoSexFemale ? @"女性" : @"男性";
        NSString *handlisghtStr = infoModel.handlight == -1 ? @"关闭" : @"打开";
        NSString *isFashrenheitStr = infoModel.isFahrenheit ? @"华氏度" : @"摄氏度";
        NSString *maxHeartWarringON = model.healthTimingModel.waringON == NO ? @"关闭" : @"打开";
        LWLog(@"【UTE】*** 向手表更新个人信息设置：\n身高:%f\n体重：%f\n年龄：%ld\n性别：%@\n运动目标：%ld步\n抬腕亮屏状态：%@\n亮屏时长：%ld秒\n手表温度单位：%@\n心率预警开关状态：%@\n心率预警最大值：%ld", infoModel.heigh, infoModel.weight, infoModel.age, sexStr, infoModel.sportTarget, handlisghtStr, infoModel.lightTime, isFashrenheitStr, maxHeartWarringON, model.healthTimingModel.maxValue);
        
        if (status) {
            LWLog(@"【UTE】*** 设置个人信息成功");
            success(@(YES));
        } else {
            LWLog(@"【UTE】*** 设置个人信息失败");
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:100 userInfo:@{@"message":@"Failure"}];
            failure(error);
        }
        
    } else {
        
        [LWFunctionSwitchRecord saveHeartMonitorONStatus:YES]; // 默认心率监测开启
        [LWFunctionSwitchRecord saveMaximumWarningValueOfHeartRate:150]; // 最大心率值提醒 初始化值
        [LWFunctionSwitchRecord saveWristWakeONStatus:YES]; // 默认抬腕亮屏是开启的
        [LWFunctionSwitchRecord saveDurationOfBrightScreen:10]; // 默认亮屏时长10秒
        [LWFunctionSwitchRecord saveHeartRateRemindONStatus:NO]; // 默认心率监测的心率预警开关：关闭
        
        // 设置身高
        infoModel.heigh = LWUserInfoManager.getUserInfo.height;
        // 设置体重
        infoModel.weight = LWUserInfoManager.getUserInfo.weight;
        // 运动目标
        infoModel.sportTarget = LWUserInfoManager.getUserInfo.stepGoal;
        // 设置抬腕亮屏
        infoModel.handlight = [LWFunctionSwitchRecord readWristWakeONStatus];
        // 手表亮屏时间(秒)
        infoModel.lightTime = [LWFunctionSwitchRecord readDurationOfBrightScreen];
        // 设置年龄
        infoModel.age = age;
        // 设置性别
        infoModel.sex = gender == 2 ? UTEDeviceInfoSexFemale : UTEDeviceInfoSexMale;

        RLMUTEUserInfoModel *model = RLMUTEUserInfoModel.new;
        model.keyID = LWDeviceInfo.getAppName;
        model.heigh = infoModel.heigh;
        model.weight = infoModel.weight;
        model.sportTarget = infoModel.sportTarget;
        model.age = infoModel.age;
        model.sex = infoModel.sex;
        
        RLMUTEWristWakeModel *wristWakeModel = RLMUTEWristWakeModel.new;
        wristWakeModel.keyID = LWDeviceInfo.getAppName;
        wristWakeModel.on = infoModel.handlight;
        wristWakeModel.interval = infoModel.lightTime;
        wristWakeModel.begin = 0;// UTE的没有起止时间 手表默认是全天
        wristWakeModel.end = 1439;// UTE的没有起止时间 手表默认是全天
        
        RLMUTEHealthTimingModel *healthTimingModel = RLMUTEHealthTimingModel.new;
        healthTimingModel.keyID = LWDeviceInfo.getAppName;
        healthTimingModel.on = [LWFunctionSwitchRecord readHeartMonitorONStatus];
        healthTimingModel.begin = 0;// UTE的没有起止时间 手表默认是全天
        healthTimingModel.end = 1439;// UTE的没有起止时间 手表默认是全天
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasMaxHeartAlert) {
            // 设置心率预警
            infoModel.maxHeart = [LWFunctionSwitchRecord readMaximumWarningValueOfHeartRate];
            healthTimingModel.maxValue = infoModel.maxHeart;
            healthTimingModel.waringON = [LWFunctionSwitchRecord readHeartRateRemindONStatus];
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasMinHeartAlert) {
            infoModel.minHeart = 50;
            healthTimingModel.minValue = infoModel.minHeart;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSleepAux) {
            infoModel.sleepAux = UTEDeviceSleepAuxTypeOpen;
            model.sleepAux = infoModel.sleepAux;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSmartLost) {
            infoModel.isSmartLost = NO;
            model.isSmartLost = infoModel.isSmartLost;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSwitchCH_EN) {
            infoModel.languageIsChinese = YES;
            model.languageIsChinese = infoModel.languageIsChinese;
        }
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSwitchTempUnit) {
            // 设置温度单位
            infoModel.isFahrenheit = LWUserInfoManager.getUserInfo.temperature == 2 ? YES : NO;
            model.isFahrenheit = infoModel.isFahrenheit;
        }
        
        model.wristwakeModel = wristWakeModel;
        model.healthTimingModel = healthTimingModel;
        
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [RLMRealm.defaultRealm addOrUpdateObject:model];
        }];
        
        // 是否设置成功
        BOOL status = [[UTESmartBandClient sharedInstance] setUTEInfoModel:infoModel];
        
        NSString *sexStr = infoModel.sex == UTEDeviceInfoSexFemale ? @"女性" : @"男性";
        NSString *handlisghtStr = infoModel.handlight == -1 ? @"关闭" : @"打开";
        NSString *isFashrenheitStr = infoModel.isFahrenheit ? @"华氏度" : @"摄氏度";
        NSString *maxHeartStr = infoModel.maxHeart == -1 ? @"关闭" : @"打开";
        LWLog(@"【UTE】*** 初始化手表个人信息设置：\n身高:%f\n体重：%f\n年龄：%ld\n性别：%@\n运动目标：%ld步\n抬腕亮屏状态：%@\n亮屏时长：%ld秒\n手表温度单位：%@\n心率预警开关状态：%@\n心率预警最大值：%ld", infoModel.heigh, infoModel.weight, infoModel.age, sexStr, infoModel.sportTarget, handlisghtStr, infoModel.lightTime, isFashrenheitStr, maxHeartStr, infoModel.maxHeart);
        
        // 保存抬腕亮屏的开关状态
        [LWFunctionSwitchRecord saveWristWakeONStatus:infoModel.handlight];
        // 保存抬腕亮屏的亮屏时长
        [LWFunctionSwitchRecord saveDurationOfBrightScreen:infoModel.lightTime];
        // 保存24h心率监测的开关状态
        [LWFunctionSwitchRecord saveHeartMonitorONStatus:healthTimingModel.on];
        // 保存心率监测的心率预警最大值
        [LWFunctionSwitchRecord saveMaximumWarningValueOfHeartRate:healthTimingModel.maxValue];
        
        if (status) {
            LWLog(@"【UTE】*** 设置个人信息成功");
            success(@(YES));
        } else {
            LWLog(@"【UTE】*** 设置个人信息失败");
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:100 userInfo:@{@"message":@"Failure"}];
            failure(error);
        }
    }
}

#pragma mark - 女性健康设置
///  女性健康设置
+ (void)setUTEWomenHealthConfig:(NSDictionary *)param
                            success:(void(^)(id result))success
                            failure:(void(^)(NSError *error))failure {

    UTEModelDeviceMenstruation *model = [[UTEModelDeviceMenstruation alloc] init];

    NSInteger duration = [param[@"duration"] integerValue]; // 经期长度
    NSInteger cycle = [param[@"cycle"] integerValue]; // 周期长度
    NSString *begin = param[@"begin"]; // 最近一次经期，格式：yyyy-MM-dd
    BOOL remindOn = [param[@"remindOn"] boolValue];
    
    model.firstTime = begin;
    model.duration = duration;
    model.cycle = cycle;
    model.openReminder = remindOn;
    
    BOOL isSendSuccess = [[UTESmartBandClient sharedInstance] sendMenstruationRemind:model];
    LWLog(@"【UTE】*** 向手表设置女性健康提醒指令发送状态 %@", isSendSuccess?@"成功":@"失败");
    if (isSendSuccess) {
        success(@(YES));
    } else {
    
    }
}

#pragma mark - 【SET】即时拍照
/// 即时拍照
+ (void)setUTEInstantPhotoStatus:(NSDictionary *)param
                         success:(void(^)(id result))success
                         failure:(void(^)(NSError *error))failure {
    NSInteger status = [param[@"status"] boolValue];
    
    if (status == 1) {
        [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionOpenCameraMode];

    } else {
        [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionCloseCameraMode];
    }
    BOOL isSendSuccess = [[UTESmartBandClient sharedInstance] checkUTEDevicesStateIsEnable];
    LWLog(@"【UTE】*** 向手表发起打开拍照模式的指令发送状态 %@", isSendSuccess?@"成功":@"失败");
    
    if (isSendSuccess) {
        if (success) {
            success(@(YES));
        }
    } else {
        
    }
}

#pragma mark - 【SET】设置通知开关
/// 设置通知开关
+ (void)setUTEMessageNotification:(LWDeviceMessageNoticeModel *)setting
                          success:(void(^)(id result))success
                          failure:(void(^)(NSError *error))failure {
    
}

#pragma mark - 【GET】设置通知开关
/// 设置通知开关
+ (void)requestUTEMessageNotification:(void(^)(id result))success
                              failure:(void(^)(NSError *error))failure {
    
}

#pragma mark - 【GET】获取久坐提醒设置
/// 获取久坐提醒设置
+ (void)requestUTERemindTime:(void(^)(id result))success
                     failure:(void(^)(NSError *error))failure {
    
    NSDictionary *result = nil;
    
    RLMUTESedentaryModel *model = [RLMUTESedentaryModel.allObjects lastObject];
    if (model) {
        result = @{
            @"on" : @(model.on),
            @"begin" : @(model.begin),
            @"end" : @(model.end),
            @"interval" : @(model.interval),
            @"siestaON" : @(model.siestaON)
        };
    } else {
        // 兼容旧版本
        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_SedentaryRemind_Settings];
    }
    
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】设置久坐提醒
/// 设置久坐提醒
+ (void)setSedentaryRemind:(NSDictionary *)param
                   success:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure {
    
    BOOL onStatus = [param[@"on"] boolValue];
    NSInteger begin = [param[@"begin"] integerValue];
    NSInteger end = [param[@"end"] integerValue];
    NSString *beginStr = [NSString stringWithFormat:@"%02ld:%02ld", begin/60, begin%60];
    NSString *endStr = [NSString stringWithFormat:@"%02ld:%02ld", end/60, end%60];
    NSInteger interval = [param[@"interval"] integerValue];
    BOOL siestaON = [param[@"siestaON"] boolValue];
    
    RLMUTESedentaryModel *model = RLMUTESedentaryModel.new;
    model.keyID = LWDeviceInfo.getAppName;
    model.on = onStatus;
    model.begin = begin;
    model.end = end;
    model.interval = interval;
    model.siestaON = siestaON;
    
    [RLMRealm.defaultRealm transactionWithBlock:^{
        [RLMRealm.defaultRealm addOrUpdateObject:model];
    }];
    
    // 兼容旧版本
    // 存储久坐信息
    [NSUserDefaults.standardUserDefaults setObject:param forKey:UTE_SedentaryRemind_Settings];
    
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSitRemindDuration == YES) {
        UTEModelDeviceSitRemind *sitRemindModel = UTEModelDeviceSitRemind.new;
        sitRemindModel.enable = onStatus;
        sitRemindModel.startTime = beginStr;
        sitRemindModel.endTime = endStr;
        sitRemindModel.duration = interval;
        sitRemindModel.enableSiesta = siestaON;
        LWLog(@"【UTE】*** 可设置时间段(久坐后，设备会提醒)");
        [[UTESmartBandClient sharedInstance] sendUTESitRemindModel:sitRemindModel];
    } else {
        LWLog(@"【UTE】*** 不可以设置时间段,午休和晚上不会提醒");
        [[UTESmartBandClient sharedInstance] setUTESitRemindOpenTime:interval];
    }
    
    if (success) {
        success(@(YES));
    }
}

#pragma mark - 【GET】获取喝水提醒设置
/// 获取喝水提醒
+ (void)requestUTEDrinkRemindSetting:(void(^)(id result))success
                          failure:(void(^)(NSError *error))failure {
    
    NSDictionary *result = nil;
    
    RLMUTEDrinkModel *model = [RLMUTEDrinkModel.allObjects lastObject];
    if (model) {
        result = @{
            @"on" : @(model.on),
            @"begin" : @(model.begin),
            @"end" : @(model.end),
            @"interval" : @(model.interval)
        };
    } else {
        // 兼容旧版本
        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_DrinkwaterRemind_Settings];
    }
    
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】设置喝水提醒
/// 设置喝水提醒
+ (void)setUTEDrinkRemind:(NSDictionary *)param
               success:(void(^)(id result))success
               failure:(void(^)(NSError *error))failure {
    
    BOOL onStatus = [param[@"on"] boolValue];
    NSInteger begin = [param[@"begin"] integerValue];
    NSInteger end = [param[@"end"] integerValue];
    NSString *beginStr = [NSString stringWithFormat:@"%02ld:%02ld", begin/60, begin%60];
    NSString *endStr = [NSString stringWithFormat:@"%02ld:%02ld", end/60, end%60];
    NSInteger intervalTime = [param[@"interval"] integerValue];
    
    LWLog(@"【UTE】*** 当前手表 %@ 喝水提醒", [UTESmartBandClient sharedInstance].connectedDevicesModel.isHasDrinkWaterReminder ? @"支持" : @"不支持");

    BOOL isSendSuccess = [[UTESmartBandClient sharedInstance] setUTEDeviceReminderDrinkWaterOpen:onStatus intervalTime:intervalTime startTime:beginStr endTime:endStr vibrate:2 siesta:YES];
    LWLog(@"【UTE】*** 向手表设置喝水提醒指令发送状态 %@", isSendSuccess?@"成功":@"失败");
    if (isSendSuccess) {
        
        RLMUTEDrinkModel *model = RLMUTEDrinkModel.new;
        model.keyID = LWDeviceInfo.getAppName;
        model.on = onStatus;
        model.begin = begin;
        model.end = end;
        model.interval = intervalTime;
        model.vibrate = 2; // App 没有这个入口设置，默认为2
        model.siestaON = NO; // 午休免打扰 App 没有这个入口设置，默认为NO
        
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [RLMRealm.defaultRealm addOrUpdateObject:model];
        }];
        
        // 兼容旧版本
        // 存储喝水提醒式信息
        [NSUserDefaults.standardUserDefaults setObject:param forKey:UTE_DrinkwaterRemind_Settings];
        
        if (success) {
            success(@(YES));
        }
    } else {
        
    }
}

#pragma mark - 【GET】获取勿扰模式设置
/// 获取勿扰模式
+ (void)requestUTEDoNotDisturbSetting:(void(^)(id result))success
                           failure:(void(^)(NSError *error))failure {
    
    NSDictionary *result = nil;
    
    RLMUTEDoNotDisturbModel *model = [RLMUTEDoNotDisturbModel.allObjects lastObject];
    if (model) {
        result = @{
            @"on" : @(model.on),
            @"periodBegin" : @(model.begin),
            @"periodEnd" : @(model.end)
        };
    } else {
        // 兼容旧版本
        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_DoNotDisturb_Settings];
    }
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】勿扰模式设置
/// 设置勿扰模式
+ (void)setUTEDoNotDisturbSetting:(NSDictionary *)param
                          success:(void(^)(id result))success
                          failure:(void(^)(NSError *error))failure {
    
    BOOL dndEnable = [param[@"on"] boolValue];
    NSInteger begin = [param[@"periodBegin"] integerValue];
    NSInteger end = [param[@"periodEnd"] integerValue];
    NSString *beginStr = [NSString stringWithFormat:@"%02ld:%02ld", begin/60, begin%60];
    NSString *endStr = [NSString stringWithFormat:@"%02ld:%02ld", end/60, end%60];
    
    
    [[UTESmartBandClient sharedInstance] sendUTEAllTimeSilence:UTESilenceTypeNone exceptStartTime:beginStr endTime:endStr except:dndEnable];
    
    RLMUTEDoNotDisturbModel *model = RLMUTEDoNotDisturbModel.new;
    model.keyID = LWDeviceInfo.getAppName;
    model.on = dndEnable;
    model.begin = begin;
    model.end = end;
    
    [RLMRealm.defaultRealm transactionWithBlock:^{
        [RLMRealm.defaultRealm addOrUpdateObject:model];
    }];
    
    // 兼容旧版本
    // 存储勿扰模式信息
    [NSUserDefaults.standardUserDefaults setObject:param forKey:UTE_DoNotDisturb_Settings];
    
    if (success) {
        success(@(YES));
    }
}

#pragma mark - 【GET】获取抬腕亮屏设置
/// 获取抬腕亮屏设置
+ (void)requestUTEWristWakeUpSetting:(void(^)(id result))success
                             failure:(void(^)(NSError *error))failure {
    NSDictionary *result = nil;
    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
    RLMUTEWristWakeModel *model = infoModel.wristwakeModel;
    if (model) {
        result = @{@"on" : @(model.on),
                   @"begin" : @(0),
                   @"end" : @(1439),
                   @"lightTime" : @(model.interval)
        };
    } else {
        // 兼容旧版本
        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_WristWakeUp_Settings];
    }
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】抬腕亮屏设置
/// 设置抬腕亮屏
+ (void)setUTEWristWakeUpSetting:(NSDictionary *)param
                          success:(void(^)(id result))success
                         failure:(void(^)(NSError *error))failure {
    
    // UTE 的抬腕亮屏没有起止时间段 只有全天候 只能设置亮屏的时长（App 暂无此设置入口，初始化的默认值为10s）
    BOOL onStatus = [param[@"on"] boolValue];
    NSInteger lightTime = [param[@"lightTime"] integerValue];
    
    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
    RLMUTEWristWakeModel *model = infoModel.wristwakeModel;
    if (model) {
        
        RLMUTEWristWakeModel *update_wristWakeModel = RLMUTEWristWakeModel.new;
        update_wristWakeModel.keyID = LWDeviceInfo.getAppName;
        update_wristWakeModel.on = onStatus;
        update_wristWakeModel.interval = lightTime;
        update_wristWakeModel.begin = model.begin;
        update_wristWakeModel.end = model.end;
        
        RLMUTEUserInfoModel *update_infoModel = RLMUTEUserInfoModel.new;
        update_infoModel.keyID = LWDeviceInfo.getAppName;
        update_infoModel.heigh = infoModel.heigh;
        update_infoModel.weight = infoModel.weight;
        update_infoModel.sportTarget = infoModel.sportTarget;
        update_infoModel.sleepAux = infoModel.sleepAux;
        update_infoModel.age = infoModel.age;
        update_infoModel.sex = infoModel.sex;
        update_infoModel.isSmartLost = infoModel.isSmartLost;
        update_infoModel.languageIsChinese = infoModel.languageIsChinese;
        update_infoModel.isFahrenheit = infoModel.isFahrenheit;
        update_infoModel.healthTimingModel = infoModel.healthTimingModel;
        
        // 更新
        update_infoModel.wristwakeModel = update_wristWakeModel;

        [RLMRealm.defaultRealm transactionWithBlock:^{
            [RLMRealm.defaultRealm addOrUpdateObject:update_infoModel];
        }];
        
        // 重新走一遍 设置手表个人信息
        NSDictionary * _Nullable dict = nil;
        [UTEBLEDeviceManager setUTEUserProfile:dict success:success failure:failure];
    } else {
        // 兼容旧版本
    }

}

//#pragma mark - 【GET】获取抬腕亮屏时长
///// 获取抬腕亮屏时长
//+ (void)requestUTEDurationOfBrightScreen:(void(^)(id result))success
//                                 failure:(void(^)(NSError *error))failure {
//    NSDictionary *result = nil;
//    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
//    RLMUTEWristWakeModel *model = infoModel.wristwakeModel;
//    if (model) {
//        result = @{@"on" : @(model.on),
//                   @"begin" : @(0),
//                   @"end" : @(1439),
//                   @"lightTime" : @(model.interval)
//        };
//    } else {
//        // 兼容旧版本
//        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_WristWakeUp_Settings];
//    }
//    GCD_MAIN_QUEUE(^{success(result);});
//}
//
//#pragma mark - 【SET】设置抬腕亮屏时长
///// 设置抬腕亮屏时长
//+ (void)setUTEDurationOfBrightScreen:(NSDictionary *)param
//                             success:(void(^)(id result))success
//                             failure:(void(^)(NSError *error))failure {
//    
//}

#pragma mark - 【GET】获取健康定时监测
/// 获取健康定时监测设置
+ (void)requestUTEHealthTimingMonitor:(void(^)(id result))success
                              failure:(void(^)(NSError *error))failure {
 
    NSDictionary *result = nil;
    
    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
    RLMUTEHealthTimingModel *model = infoModel.healthTimingModel;
    if (model) {
        result = @{
            @"on" : @(model.on),
            @"begin" : @(model.begin),
            @"end" : @(model.end)
        };
    } else {
        result = [NSUserDefaults.standardUserDefaults objectForKey: UTE_HealthTimingMonitor_Settings];
    }
    GCD_MAIN_QUEUE(^{success(result);});
}

#pragma mark - 【SET】设置健康定时监测
/// 设置健康定时监测
+ (void)setUTEHealthTimingMonitor:(NSDictionary *)param
                       success:(void(^)(id result))success
                       failure:(void(^)(NSError *error))failure {
    
    BOOL onStatus = [param[@"on"] boolValue];
    NSInteger begin = [param[@"begin"] integerValue];
    NSInteger end = [param[@"end"] integerValue];
    // UTE的没有心率间隔设置 忽略即可
//    NSInteger intervalTime = [param[@"interval"] integerValue];
    
    BOOL sendComand = [[UTESmartBandClient sharedInstance] setUTEOption: onStatus ? UTEOptionOpen24HourHRM : UTEOptionClose24HourHRM];
    LWLog(@"【UTE】*** 心率设置: %@ 24h实时监测 %@",  onStatus ? @"打开" : @"关闭", sendComand ? @"成功" : @"失败");
    
    if (sendComand) {
        
        RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
        RLMUTEHealthTimingModel *model = infoModel.healthTimingModel;
        if (model) {
                        
            RLMUTEHealthTimingModel *update_healthTimingModel = RLMUTEHealthTimingModel.new;
            update_healthTimingModel.keyID = LWDeviceInfo.getAppName;
            update_healthTimingModel.on = onStatus;
            update_healthTimingModel.begin = begin;
            update_healthTimingModel.end = end;
            update_healthTimingModel.waringON = model.waringON;
            update_healthTimingModel.maxValue = model.maxValue;
            update_healthTimingModel.minValue = model.minValue;
            
            RLMUTEUserInfoModel *update_infoModel = RLMUTEUserInfoModel.new;
            update_infoModel.keyID = LWDeviceInfo.getAppName;
            update_infoModel.heigh = infoModel.heigh;
            update_infoModel.weight = infoModel.weight;
            update_infoModel.sportTarget = infoModel.sportTarget;
            update_infoModel.sleepAux = infoModel.sleepAux;
            update_infoModel.age = infoModel.age;
            update_infoModel.sex = infoModel.sex;
            update_infoModel.isSmartLost = infoModel.isSmartLost;
            update_infoModel.languageIsChinese = infoModel.languageIsChinese;
            update_infoModel.isFahrenheit = infoModel.isFahrenheit;
            update_infoModel.wristwakeModel = infoModel.wristwakeModel;
            
            // 更新
            update_infoModel.healthTimingModel = update_healthTimingModel;
            
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addOrUpdateObject:update_infoModel];
            }];
            
            // 重新走一遍 设置手表个人信息
            NSDictionary * _Nullable dict = nil;
            [UTEBLEDeviceManager setUTEUserProfile:dict success:success failure:failure];
        } else {
            // 兼容旧版本
            // 存储心率设置
            [NSUserDefaults.standardUserDefaults setObject:param forKey:UTE_HealthTimingMonitor_Settings];
        }
    } else {
        
    }
}

#pragma mark - 【GET】获取心率上限预警
/// 获取心率上限预警
+ (void)getHeartRateWarning:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure {
    
    NSDictionary *result = nil;
    
    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
    RLMUTEHealthTimingModel *model = infoModel.healthTimingModel;
    if (model) {
        result = @{@"toplimitSwitch" : @(model.waringON),
                   @"toplimitValue" : @(model.maxValue)
        };
    } else {
        BOOL toplimitSwitch = [LWFunctionSwitchRecord readHeartRateRemindONStatus];
        NSInteger toplimitValue = [LWFunctionSwitchRecord readMaximumWarningValueOfHeartRate];
        result = @{@"toplimitSwitch" : @(toplimitSwitch),
                   @"toplimitValue" : @(toplimitValue)
        };
    }
    GCD_MAIN_QUEUE(^{success(result);});
}


#pragma mark - 【SET】设置心率上限预警
/// 设置心率上线预警
+ (void)setHeartRateWarning:(NSDictionary *)param
                    success:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure {
    
    BOOL onStatus = [param[@"toplimitSwitch"] boolValue];
    NSInteger maxHeartValue = [param[@"toplimitValue"] integerValue];
    
    RLMUTEUserInfoModel *infoModel = [RLMUTEUserInfoModel.allObjects lastObject];
    RLMUTEHealthTimingModel *model = infoModel.healthTimingModel;
    if (model) {
        
        RLMUTEHealthTimingModel *update_healthTimingModel = RLMUTEHealthTimingModel.new;
        update_healthTimingModel.keyID = LWDeviceInfo.getAppName;
        update_healthTimingModel.on = onStatus;
        update_healthTimingModel.begin = model.begin;
        update_healthTimingModel.end = model.end;
        update_healthTimingModel.minValue = model.minValue;
        update_healthTimingModel.waringON = onStatus;
        update_healthTimingModel.maxValue = maxHeartValue;
        
        RLMUTEUserInfoModel *update_infoModel = RLMUTEUserInfoModel.new;
        update_infoModel.keyID = LWDeviceInfo.getAppName;
        update_infoModel.heigh = infoModel.heigh;
        update_infoModel.weight = infoModel.weight;
        update_infoModel.sportTarget = infoModel.sportTarget;
        update_infoModel.sleepAux = infoModel.sleepAux;
        update_infoModel.age = infoModel.age;
        update_infoModel.sex = infoModel.sex;
        update_infoModel.isSmartLost = infoModel.isSmartLost;
        update_infoModel.languageIsChinese = infoModel.languageIsChinese;
        update_infoModel.isFahrenheit = infoModel.isFahrenheit;
        update_infoModel.wristwakeModel = infoModel.wristwakeModel;
        
        // 更新
        update_infoModel.healthTimingModel = update_healthTimingModel;
        
        [RLMRealm.defaultRealm transactionWithBlock:^{
            [RLMRealm.defaultRealm addOrUpdateObject:update_infoModel];
        }];
        
        // 重新走一遍 设置手表个人信息
        NSDictionary * _Nullable dict = nil;
        [UTEBLEDeviceManager setUTEUserProfile:dict success:success failure:failure];
    } else {
        // 兼容旧版本
    }
    
}

#pragma mark - 【GET】获取闹钟
/// 获取闹钟设置
+ (void)getAlarmUTEClockBlock:(void(^)(id result))success
                      failure:(void(^)(NSError *error))failure {
    
    if ([UTEBLEDeviceManager defaultManager].deviceInfo.isHasClockTitle) {
        
        [[UTESmartBandClient sharedInstance] readUTEAlarm:^(NSArray<UTEModelAlarm *> * _Nullable array, BOOL success) {
            
        }];
        
    } else {
        
        NSMutableArray *mutArray = @[].mutableCopy;
        
        RLMResults *results = [RLMUTEAlarmModel.allObjects sortedResultsUsingKeyPath:@"clockId" ascending:YES]; // 对查询结果排序
        
        for (RLMUTEAlarmModel *model in results) {
            NSMutableArray *cycle = @[].mutableCopy;
            if (model.day7Enable == 1) {
                [cycle addObject:@"0"];
            }
            if (model.day1Enable == 1) {
                [cycle addObject:@"1"];
            }
            if (model.day2Enable == 1) {
                [cycle addObject:@"2"];
            }
            if (model.day3Enable == 1) {
                [cycle addObject:@"3"];
            }
            if (model.day4Enable == 1) {
                [cycle addObject:@"4"];
            }
            if (model.day5Enable == 1) {
                [cycle addObject:@"5"];
            }
            if (model.day6Enable == 1) {
                [cycle addObject:@"6"];
            }
            
//            NSDate *date = [NSDate dateWithString:[NSString stringWithFormat:@"%ld-%02ld-%02ld %02ld:%02ld", NSDate.date.year, NSDate.date.month, NSDate.date.day, model.hour, model.min] format:@"yyyy-MM-dd HH:mm"];
            NSTimeInterval timeInterval = model.clockTimeStamp;
            
            LWClockRemindType clockRemindType;
            if (cycle.count > 0) {
                if ([cycle containsObject:@"1"] &&
                    [cycle containsObject:@"2"] &&
                    [cycle containsObject:@"3"] &&
                    [cycle containsObject:@"4"] &&
                    [cycle containsObject:@"5"] &&
                    cycle.count == 5) {
                    clockRemindType = LWClockRemindTypeWorkingDay;
                }
                else if (cycle.count == 7) {
                    clockRemindType = LWClockRemindTypeEveryDay;
                }
                else {
                    clockRemindType = LWClockRemindTypeCustomize;
                }
                
            } else {
                clockRemindType = LWClockRemindTypeRingOnce;
            }
            
            NSDictionary *dic = @{@"on" : @(model.enable),
                                  @"cycle" : cycle,
                                  @"fire" : @(timeInterval),
                                  @"label" : IF_NULL_TO_STRING(model.clockNote),
                                  @"index" : @(model.clockId),
                                  @"clockRemindType" : @(clockRemindType)
            };
            [mutArray addObject:dic];
        }
        
        NSDictionary *result = @{@"alarms" : mutArray.copy};
        if (success) {
            GCD_MAIN_QUEUE(^{success(result);});
        }
        
    }
    
}

#pragma mark - 【SET】设置闹钟
/// 设置闹钟
+ (void)setAlarmUTEAddClock:(NSDictionary *)param
                   succcess:(void(^)(id result))success
                    failure:(void(^)(NSError *error))failure {
    
    NSInteger index = [param[@"index"] integerValue] + 1;
    
    NSError *error = nil;
//    if (error) {
//        if (failure) {
//            failure(error);
//        }
//    } else
        
    if (index > LWDeviceRequestManager.allowSupportAlarmCount) {
        error = [NSError errorWithDomain:[NSString stringWithFormat:LWLocalizbleString(@"最多设置%d个闹钟"), LWDeviceRequestManager.allowSupportAlarmCount] code:500 userInfo:@{@"message" : [NSString stringWithFormat:LWLocalizbleString(@"最多设置%d个闹钟"), LWDeviceRequestManager.allowSupportAlarmCount]}];
        if (failure) {
            failure(error);
            return;
        }
    } else {
        
        NSMutableArray *alarmArrM = NSMutableArray.new;
        // 遍历查询本地数据库的闹钟
        RLMResults *results = [RLMUTEAlarmModel.allObjects sortedResultsUsingKeyPath:@"clockId" ascending:YES]; // 对查询结果排序
        if (results.count) {
            for (RLMUTEAlarmModel *savedAlarmModel in results) {
                
                UTEModelAlarm *setUp = UTEModelAlarm.new;
                setUp.num = savedAlarmModel.clockId;
                setUp.time = savedAlarmModel.clockTime;
                setUp.enable = savedAlarmModel.enable;
                setUp.countVibrate = savedAlarmModel.countVibrate;
                
                UTEAlarmWeek cycle = 0;
                if (savedAlarmModel.day7Enable) {
                    cycle = UTEAlarmWeekSunday;
                }
                if (savedAlarmModel.day1Enable) {
                    cycle = UTEAlarmWeekMonday;
                }
                if (savedAlarmModel.day2Enable) {
                    cycle = UTEAlarmWeekTuesday;
                }
                if (savedAlarmModel.day3Enable) {
                    cycle = UTEAlarmWeekWednesday;
                }
                if (savedAlarmModel.day4Enable) {
                    cycle = UTEAlarmWeekThursday;
                }
                if (savedAlarmModel.day5Enable) {
                    cycle = UTEAlarmWeekFriday;
                }
                if (savedAlarmModel.day6Enable) {
                    cycle = UTEAlarmWeekSaturday;
                }
                setUp.week = cycle;
                
                setUp.vibrationIntensity = savedAlarmModel.vibrationIntensity;
                setUp.title = savedAlarmModel.clockNote;
                setUp.once = savedAlarmModel.oneTimeEnable;
                setUp.timeRecord = savedAlarmModel.editClockTimeStr;
                
                [alarmArrM addObject:setUp];
            }
        }
        
        // 闹钟时间戳
        NSInteger clockTimeStamp = [param[@"fire"] integerValue];
        // 转换成 Date
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:clockTimeStamp];
        // 转换成 HH:mm 格式时间字符串
        NSString *alarmTime = [date stringWithFormat:@"HH:mm"];
        // 闹钟开关
        NSInteger enable = [param[@"on"] boolValue] ? 1 : 0;
        // 闹钟时间：时
        NSInteger hour = date.hour;
        // 闹钟时间：分
        NSInteger minute = date.minute;
        // 提醒周期
        NSArray *ary = param[@"cycle"];
        // 是否为一次性闹钟
        NSInteger oneTimeEnable = ary.count ? 0 : 1;
        // 闹钟备注
        NSString *remark = IF_NULL_TO_STRING(param[@"remark"]);
        
        NSDate *currentDate = [NSDate date];
        NSString *editClockTimeStr = [currentDate stringWithFormat:@"yyyy-MM-dd-HH-mm-ss"];
        
        UTEModelAlarm *setUp = UTEModelAlarm.new;
        setUp.num = index;
        setUp.time = alarmTime;
        setUp.enable = enable;
        setUp.countVibrate = 5; // 震动强度 默认5 App没有供用户设置的入口
        
        
        RLMUTEAlarmModel *model = RLMUTEAlarmModel.new;
        model.clockId = setUp.num;
        model.enable = setUp.enable;
        model.clockTimeStamp = clockTimeStamp;
        model.hour = hour;
        model.min = minute;
        model.clockTime = alarmTime;
        model.clockNote = remark;
        model.editClockTimeStr = editClockTimeStr;
        model.oneTimeEnable = oneTimeEnable;
        
        
        UTEAlarmWeek cycle = 0;
        if ([ary containsObject:@"0"] || [ary containsObject:@"7"]) {
            cycle = UTEAlarmWeekSunday;
            model.day7Enable = 1;
        }
        if ([ary containsObject:@"1"]) {
            cycle = UTEAlarmWeekMonday;
            model.day1Enable = 1;
        }
        if ([ary containsObject:@"2"]) {
            cycle = UTEAlarmWeekTuesday;
            model.day2Enable = 1;
        }
        if ([ary containsObject:@"3"]) {
            cycle = UTEAlarmWeekWednesday;
            model.day3Enable = 1;
        }
        if ([ary containsObject:@"4"]) {
            cycle = UTEAlarmWeekThursday;
            model.day4Enable = 1;
        }
        if ([ary containsObject:@"5"]) {
            cycle = UTEAlarmWeekFriday;
            model.day5Enable = 1;
        }
        if ([ary containsObject:@"6"]) {
            cycle = UTEAlarmWeekSaturday;
            model.day6Enable = 1;
        }
        setUp.week = cycle;
        
        if ([UTEBLEDeviceManager defaultManager].deviceInfo.isHasClockShow) {
            setUp.hidden = NO;
        }
        
        if ([UTEBLEDeviceManager defaultManager].deviceInfo.isHasClockTitle) {
            LWLog(@"【UTE】*** 当前手表支持备注，一次性闹钟");
            setUp.vibrationIntensity = 3;
            setUp.title = remark;
            setUp.once = oneTimeEnable;
            setUp.timeRecord = editClockTimeStr;
            
            [alarmArrM addObject:setUp];
            [[UTESmartBandClient sharedInstance] setUTEAlarmArray:alarmArrM.mutableCopy vibrate:5 result:^(BOOL succeed) {
                if (succeed) {
                    if (success) {
                        success(@(succeed));
                    }
                    [RLMRealm.defaultRealm transactionWithBlock:^{
                        [RLMRealm.defaultRealm addOrUpdateObject:model];
                    }];
                } else {
                    if (failure) {
                        failure(error);
                    }
                }
            }];
            
        } else {
            
            [alarmArrM addObject:setUp];
            BOOL isSendSuccess = [[UTESmartBandClient sharedInstance] setUTEAlarmArray:alarmArrM.mutableCopy vibrate:5];
            LWLog(@"【UTE】*** 向手表设置闹钟指令发送状态 %@", isSendSuccess?@"成功":@"失败");
            if (isSendSuccess) {
                if (success) {
                    success(@(YES));
                }
                [RLMRealm.defaultRealm transactionWithBlock:^{
                    [RLMRealm.defaultRealm addOrUpdateObject:model];
                }];
            } else {
                
            }
        }
    }
}

#pragma mark - 【SET】删除闹钟
/// 删除闹钟
+ (void)deleteUTEAlarm:(NSDictionary *)param
                      success:(void (^)(id _Nonnull))success
               failure:(void (^)(NSError * _Nonnull))failure {
    
    NSInteger index = [param[@"index"] integerValue] + 1;
    
    NSMutableArray *alarmArrM = NSMutableArray.new;
    // 遍历查询本地数据库的闹钟
    RLMResults *results = [RLMUTEAlarmModel.allObjects sortedResultsUsingKeyPath:@"clockId" ascending:YES]; // 对查询结果排序
    if (results.count) {
        
        for (RLMUTEAlarmModel *savedAlarmModel in results) {
            
            UTEModelAlarm *setUp = UTEModelAlarm.new;
            setUp.num = savedAlarmModel.clockId;
            setUp.time = savedAlarmModel.clockTime;
            setUp.enable = savedAlarmModel.enable;
            setUp.countVibrate = savedAlarmModel.countVibrate;
            
            UTEAlarmWeek cycle = 0;
            if (savedAlarmModel.day7Enable) {
                cycle = UTEAlarmWeekSunday;
            }
            if (savedAlarmModel.day1Enable) {
                cycle = UTEAlarmWeekMonday;
            }
            if (savedAlarmModel.day2Enable) {
                cycle = UTEAlarmWeekTuesday;
            }
            if (savedAlarmModel.day3Enable) {
                cycle = UTEAlarmWeekWednesday;
            }
            if (savedAlarmModel.day4Enable) {
                cycle = UTEAlarmWeekThursday;
            }
            if (savedAlarmModel.day5Enable) {
                cycle = UTEAlarmWeekFriday;
            }
            if (savedAlarmModel.day6Enable) {
                cycle = UTEAlarmWeekSaturday;
            }
            setUp.week = cycle;
            
            setUp.vibrationIntensity = savedAlarmModel.vibrationIntensity;
            setUp.title = savedAlarmModel.clockNote;
            setUp.once = savedAlarmModel.oneTimeEnable;
            setUp.timeRecord = savedAlarmModel.editClockTimeStr;
            
            if (setUp.num != index) {
                [alarmArrM addObject:setUp];
            }
        }
    }
    
    if ([UTEBLEDeviceManager defaultManager].deviceInfo.isHasClockTitle) {
        
    } else {
        
        BOOL isSendSuccess = [[UTESmartBandClient sharedInstance] setUTEAlarmArray:alarmArrM.mutableCopy vibrate:5];
        LWLog(@"【UTE】*** 【删除闹钟】向手表设置闹钟指令发送状态 %@", isSendSuccess?@"成功":@"失败");
        if (isSendSuccess) {
            [RLMRealm.defaultRealm transactionWithBlock:^{
                for (RLMUTEAlarmModel *AlarmDataModel in results) {
                    if (AlarmDataModel.clockId == index) {
                        [RLMRealm.defaultRealm deleteObject:AlarmDataModel];
                    }
                }
                for (RLMUTEAlarmModel *AlarmDataModel in results) {
//                    if (AlarmDataModel.clockId == index + 1) {
//                        AlarmDataModel.clockId = index;
//                        [RLMRealm.defaultRealm addOrUpdateObject:AlarmDataModel];
//                    }
                }
            }];
            success(@(YES));
        } else {
            
        }
    }
}

#pragma mark - 【SET】编辑闹钟
/// 修改闹钟
+ (void)editorUTEAlarm:(NSDictionary *)param
                   success:(void (^)(id _Nonnull))success
               failure:(void (^)(NSError * _Nonnull))failure {
    
    [UTEBLEDeviceManager setAlarmUTEAddClock:param succcess:success failure:failure];
}

#pragma mark - 设置目标提醒
/// 设置目标提醒
+ (void)setUTEGoalReminder:(NSDictionary *)param
                   success:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure {
    
    // * @param stepcount 步数目标, 单位：步数
    // * @param distance 距离目标, 单位：米
    // * @param calory 卡路里, 单位：kcal
    BOOL remind = [param[@"remind"] intValue]==1 ? YES : NO;
    NSInteger step = [param[@"step"] intValue];
    NSInteger distance = [param[@"distance"] intValue] / 100;
    NSInteger calory = [param[@"calory"] intValue] / 1000;
    
    // 存储目标提醒
    [NSUserDefaults.standardUserDefaults setObject:param forKey:UTE_GoalReminder_Settings];
    
    BOOL stepTargetStatus = [[UTESmartBandClient sharedInstance] setUTEGoalReminder:UTEGoalTypeStep open:remind goal:step callback:^(UTEGoalType callbackType, BOOL callbackOpen) {
        if (callbackOpen) {
            LWLog(@"步数目标提醒 已打开");
            success(@YES);
        } else {
            LWLog(@"步数目标提醒 已关闭");
        }
    }];
    if (stepTargetStatus) {
        LWLog(@"发送 设置步数目标提醒 成功");
    } else {
        LWLog(@"发送 设置步数目标提醒 失败");
    }
    
    GCD_AFTER(0.25, ^{
        BOOL distanceTargetStatus = [[UTESmartBandClient sharedInstance] setUTEGoalReminder:UTEGoalTypeDistance open:remind goal:distance callback:^(UTEGoalType callbackType, BOOL callbackOpen) {
            if (callbackOpen) {
                LWLog(@"距离目标提醒 已打开");
                success(@YES);
            } else {
                LWLog(@"距离目标提醒 已关闭");
            }
        }];
        if (distanceTargetStatus) {
            LWLog(@"发送 设置距离目标提醒 成功");
        } else {
            LWLog(@"发送 设置距离目标提醒 失败");
        }
    });
    

    GCD_AFTER(0.5, ^{
        BOOL calorieTargetStatus = [[UTESmartBandClient sharedInstance] setUTEGoalReminder:UTEGoalTypeCalorie open:remind goal:calory callback:^(UTEGoalType callbackType, BOOL callbackOpen) {
            if (callbackOpen) {
                LWLog(@"卡路里目标提醒 已打开");
                success(@YES);
            } else {
                LWLog(@"卡路里目标提醒 已关闭");
            }
        }];
        if (calorieTargetStatus) {
            LWLog(@"发送 设置卡路里目标提醒 成功");
        } else {
            LWLog(@"发送 设置卡路里目标提醒 失败");
        }
    });
}

#pragma mark - 获取目标提醒
/// 获取目标提醒
+ (void)requestGetDailyGoalSuccess:(void(^)(id result))success
                           failure:(void(^)(NSError *error))failure {
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults objectForKey: UTE_GoalReminder_Settings];
    success(dict);
}

#pragma mark - 监听指令的回调（部份）
- (void)uteManageUTEOptionCallBack:(UTECallBack)callback {
    LWLog(@"【UTE】*** SDK 指令回调 - %ld", (long)callback);
    switch (callback) {
        case UTECallBackUnit: {
            LWLog(@"【UTE】*** 时间格式和单位公英制设置成功");
            break;
        }
        case UTECallBackInfoHeightWeight: {
            LWLog(@"【UTE】*** 个人信息设置成功");
            break;
        }
        case UTECallBackSyncTime: {
            LWLog(@"【UTE】*** 系统时间同步成功");
            break;
        }
        case UTECallBackAlarm: {
            LWLog(@"【UTE】*** 设置闹钟/查找手表成功");
            break;
        }
        case UTECallBackDeviceBattery: {
//            LWLog(@"【UTE】*** 电量读取成功");
            LWLog(@"【UTE】*** 电量读取成功，发送 sdk 初始化完毕通知（DEVICE_DID_INIT_COMPLETE），通知设备页面刷新电量");
            //  sdk 初始化完毕通知
            [NSNotificationCenter.defaultCenter postNotificationName:DEVICE_DID_INIT_COMPLETE object:@{} userInfo:nil];
            break;
        }
        case UTECallBackOpen24HourHRM: {
            LWLog(@"【UTE】*** 打开24h心率监测成功");
            break;
        }
        case UTECallBackClose24HourHRM: {
            LWLog(@"【UTE】*** 关闭24h心率监测成功");
            break;
        }
        case UTECallBackOpenUnitSitRemind: {
            LWLog(@"【UTE】*** 久坐提醒开启🔔成功");
            break;
        }
        case UTECallBackCloseSitRemind: {
            LWLog(@"【UTE】*** 久坐提醒关闭🔕成功");
            break;
        }
        case UTECallBackDeviceSilence: {
            LWLog(@"【UTE】*** 勿扰模式设置成功");
            break;
        }
        case UTECallBackOpenRemindIncall: {
            LWLog(@"【UTE】*** 来电通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindIncall: {
            LWLog(@"【UTE】*** 来电通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindQQ: {
            LWLog(@"【UTE】*** QQ通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindQQ: {
            LWLog(@"【UTE】*** QQ通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindWeixin: {
            LWLog(@"【UTE】*** 微信通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindWeixin: {
            LWLog(@"【UTE】*** 微信通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindSms: {
            LWLog(@"【UTE】*** 短信通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindSms: {
            LWLog(@"【UTE】*** 短信通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindMore: {
            LWLog(@"【UTE】*** 其它通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindMore: {
            LWLog(@"【UTE】*** 其它通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindFacebook: {
            LWLog(@"【UTE】*** Facebook通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindFacebook: {
            LWLog(@"【UTE】*** Facebook通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindFacebookMessenger: {
            LWLog(@"【UTE】*** FacebookMessenger通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindFacebookMessenger: {
            LWLog(@"【UTE】*** FacebookMessenger通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindTwitter: {
            LWLog(@"【UTE】*** Twitter通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindTwitter: {
            LWLog(@"【UTE】*** Twitter通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindWhatsApp: {
            LWLog(@"【UTE】*** WhatsApp通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindWhatsApp: {
            LWLog(@"【UTE】*** WhatsApp通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindLine: {
            LWLog(@"【UTE】*** Line通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindLine: {
            LWLog(@"【UTE】*** Line通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindSkype: {
            LWLog(@"【UTE】*** Skype通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindSkype: {
            LWLog(@"【UTE】*** Skype通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindLinkedIn: {
            LWLog(@"【UTE】*** Linkedin通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindLinkedIn: {
            LWLog(@"【UTE】*** LinkedIn通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindSnapchat: {
            LWLog(@"【UTE】*** Snapchat通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindSnapchat: {
            LWLog(@"【UTE】*** Snapchat通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindInstagram: {
            LWLog(@"【UTE】*** Instagram通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindInstagram: {
            LWLog(@"【UTE】*** Instagram通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindViber: {
            LWLog(@"【UTE】*** Viber通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindViber: {
            LWLog(@"【UTE】*** Viber通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindKaKao: {
            LWLog(@"【UTE】*** KakaoTalk通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindKaKao: {
            LWLog(@"【UTE】*** KakaoTalk通知关闭🔕成功");
            break;
        }
        case UTECallBackOpenRemindGmail: {
            LWLog(@"【UTE】*** Gmail通知打开🔔成功");
            break;
        }
        case UTECallBackCloseRemindGmail: {
            LWLog(@"【UTE】*** Gmail通知关闭🔕成功");
            break;
        }
        case UTECallBackWeatherSevenDay: {
            LWLog(@"【UTE】*** 手表7天天气设置成功");
            break;
        }
//        case UTECallBackCloseRemindGoogleChat: {
//            LWLog(@"【UTE】*** GoogleChat通知关闭🔕成功");
//            break;
//        }
            
        case UTECallBackOpenCommonHRMAuto: {
            LWLog(@"【UTE】*** 自动监测的心率值");
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - 【GET】获取消息通知设置
/// 获取消息通知设置
+ (void)requestUTEMessageNotificationReminder:(void(^)(id result))success
                                      failure:(void(^)(NSError *error))failure {
    
    LWDeviceMessageNoticeModel *model = LWDeviceMessageNoticeModel.new;
    
    RLMUTENotifiModel *savedModel = [RLMUTENotifiModel.allObjects lastObject];
    if (savedModel) {
        model.mainOn                        = savedModel.mainON;                        // 总开关
        model.call                          = savedModel.Phone;                         // 来电 提醒
        model.sms                           = savedModel.SMS;                           // 短信通知 提醒
        model.weChat                        = savedModel.Wechat;                        // 微信 提醒
        model.qq                            = savedModel.QQ;                            // qq 提醒
        model.twitter                       = savedModel.Twitter;                       // twitter 提醒
        model.facebook                      = savedModel.Facebook;                      // facebook 提醒
        model.whatsapp                      = savedModel.WhatsApp;                      // whatsapp 提醒
        model.instagram                     = savedModel.Instagram;                     // instagram 提醒
        model.linkedin                      = savedModel.LinkedIn;                      // linkedin 提醒
        model.line                          = savedModel.Line;                          // line 提醒
        model.facebook_messenger            = savedModel.FacebookMessenger;             // facebook messenger 提醒
        model.skype                         = savedModel.Skype;                         // skype 提醒
        model.snapchat                      = savedModel.Snapchat;                      // snapchat 提醒
        model.kakaoTalk                     = savedModel.KakaoTalk;                     // kakao Talk 提醒
        model.viber                         = savedModel.Viber;                         // viber 提醒
        model.telegram                      = savedModel.Telegram;                      // telegram 提醒
        model.otherApp                      = savedModel.Other;                         // 其它 提醒
        model.gmail                         = savedModel.Gmail;                         // Gmail 提醒
        
        LWLog(@"【UTE】*** 消息开关%@", savedModel);
        
        if (success) {
            success(model);
        }
        
    } else {
        
        NSDictionary *deviceInfo = [NSUserDefaults.standardUserDefaults objectForKey: UTE_Notification_Settings];
        
        model.mainOn = ([deviceInfo[@"mainON"] integerValue] == 1) ? YES : NO;

        model.call = ([deviceInfo[@"call"] integerValue] == 1) ? YES : NO;
        
        model.sms = ([deviceInfo[@"sms"] integerValue] == 1) ? YES : NO;
 
        model.qq = ([deviceInfo[@"qq"] integerValue] == 1) ? YES : NO;
        
        model.weChat = ([deviceInfo[@"weChat"] integerValue] == 1) ? YES : NO;
        
        model.twitter = ([deviceInfo[@"twitter"] integerValue] == 1) ? YES : NO;
        
        model.facebook = ([deviceInfo[@"facebook"] integerValue] == 1) ? YES : NO;
        
        model.facebook_messenger = ([deviceInfo[@"facebookMessenger"] integerValue] == 1) ? YES : NO;
        
        model.whatsapp = ([deviceInfo[@"whatsapp"] integerValue] == 1) ? YES : NO;
        
        model.instagram = ([deviceInfo[@"instagram"] integerValue] == 1) ? YES : NO;

        model.linkedin = ([deviceInfo[@"linkedin"] integerValue] == 1) ? YES : NO;
        
        model.line = ([deviceInfo[@"line"] integerValue] == 1) ? YES : NO;
        
        model.skype = ([deviceInfo[@"skype"] integerValue] == 1) ? YES : NO;
        
        model.snapchat = ([deviceInfo[@"snapchat"] integerValue] == 1) ? YES : NO;
        
        model.gmail = ([deviceInfo[@"gmail"] integerValue] == 1) ? YES : NO;
        
        model.viber = ([deviceInfo[@"viber"] integerValue] == 1) ? YES : NO;

        model.kakaoTalk = ([deviceInfo[@"kakaoTalk"] integerValue] == 1) ? YES : NO;
        
        model.youtube = ([deviceInfo[@"youtube"] integerValue] == 1) ? YES : NO;
        
        model.telegram = ([deviceInfo[@"telegram"] integerValue] == 1) ? YES : NO;

        model.otherApp = ([deviceInfo[@"other"] integerValue] == 1) ? YES : NO;
        
        success(model);
    }
}

#pragma mark - 【SET】设置消息通知
/// 设置消息通知
+ (void)setUTEMessageNotificationReminder:(LWDeviceMessageNoticeModel *)setting
                                      success:(void(^)(id result))success
                                  failure:(void(^)(NSError *error))failure {
    
    UTEModelDeviceRemindApp *model  = UTEModelDeviceRemindApp.new;
    
    model.Phone                     = setting.call                  == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.SMS                       = setting.sms                   == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.QQ                        = setting.qq                    == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.Wechat                    = setting.weChat                == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.Facebook                  = setting.facebook              == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.FacebookMessenger         = setting.facebook_messenger    == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.Twitter                   = setting.twitter               == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.WhatsApp                  = setting.whatsapp              == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.Line                      = setting.line                  == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    model.Skype                     = setting.skype                 == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSocialNotification2) {
        model.LinkedIn                  = setting.linkedin              == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
        model.Instagram                 = setting.instagram             == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
        model.KakaoTalk                 = setting.kakaoTalk             == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
        model.Snapchat                  = setting.snapchat              == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
        model.Gmail                     = setting.gmail                 == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
        
        model.Viber                     = UTEDeviceRemindClose;
        model.Vkontakte                 = UTEDeviceRemindClose;
        model.GooglePlus                = UTEDeviceRemindClose;
        model.Flickr                    = UTEDeviceRemindClose;
        model.Tumblr                    = UTEDeviceRemindClose;
        model.Pinterest                 = UTEDeviceRemindClose;
        model.YouTube                   = UTEDeviceRemindClose;
    }
    
    model.Other                     = setting.otherApp              == YES ? UTEDeviceRemindOpen : UTEDeviceRemindClose;
    
    RLMUTENotifiModel *saveModel    = RLMUTENotifiModel.new;
    saveModel.keyID                 = LWDeviceInfo.getAppName;
    saveModel.Phone                 = model.Phone                   == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.SMS                   = model.SMS                     == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.QQ                    = model.QQ                      == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.Wechat                = model.Wechat                  == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.Facebook              = model.Facebook                == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.FacebookMessenger     = model.FacebookMessenger       == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.Twitter               = model.Twitter                 == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.WhatsApp              = model.WhatsApp                == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.Line                  = model.Line                    == UTEDeviceRemindOpen ?  YES : NO;
    saveModel.Skype                 = model.Skype                   == UTEDeviceRemindOpen ?  YES : NO;
    
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSocialNotification2) {
        saveModel.LinkedIn              = model.LinkedIn            == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Instagram             = model.Instagram           == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.KakaoTalk             = model.KakaoTalk           == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Snapchat              = model.Snapchat            == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Gmail                 = model.Gmail               == UTEDeviceRemindOpen ?  YES : NO;
        
        saveModel.Viber                 = model.Viber               == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Vkontakte             = model.Vkontakte           == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.GooglePlus            = model.GooglePlus          == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Flickr                = model.Flickr              == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Tumblr                = model.Tumblr              == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.Pinterest             = model.Pinterest           == UTEDeviceRemindOpen ?  YES : NO;
        saveModel.YouTube               = model.YouTube             == UTEDeviceRemindOpen ?  YES : NO;
    }
    
    saveModel.Other                     = model.Other               == UTEDeviceRemindOpen ?  YES : NO;
    
    BOOL mainON = setting.mainOn;
    if (setting.mainOn == NO) {
        model.Phone                     = UTEDeviceRemindClose;
        model.SMS                       = UTEDeviceRemindClose;
        model.QQ                        = UTEDeviceRemindClose;
        model.Wechat                    = UTEDeviceRemindClose;
        model.Facebook                  = UTEDeviceRemindClose;
        model.FacebookMessenger         = UTEDeviceRemindClose;
        model.Twitter                   = UTEDeviceRemindClose;
        model.WhatsApp                  = UTEDeviceRemindClose;
        model.Line                      = UTEDeviceRemindClose;
        model.Skype                     = UTEDeviceRemindClose;
        
        if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSocialNotification2) {
            model.LinkedIn                  = UTEDeviceRemindClose;
            model.Instagram                 = UTEDeviceRemindClose;
            model.KakaoTalk                 = UTEDeviceRemindClose;
            model.Snapchat                  = UTEDeviceRemindClose;
            model.Gmail                     = UTEDeviceRemindClose;
        }
        model.Other                     = UTEDeviceRemindClose;
    }
    
    saveModel.mainON = mainON;
    
    // 如果 这两个 标识位支持任意一个 则调用 setUTERemindApp:model 这个方法 否则调用 setUTEOption:open/close 这种单个枚举开 单个枚举关
    if (([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSocialNotification ||
         [UTESmartBandClient sharedInstance].connectedDevicesModel.isHasSocialNotification2)) {
        
        BOOL sendComand = [[UTESmartBandClient sharedInstance] setUTERemindApp:model];
        LWLog(@"【UTE】*** 消息提醒设置:  %@",  sendComand ? @"成功" : @"失败");
        if (sendComand) {
            
            if (success) {
                success(@(YES));
            }
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addOrUpdateObject:saveModel];
            }];
        }
    }
    else {
        
        BOOL sendCallRemindComand = [[UTESmartBandClient sharedInstance] setUTEOption:setting.call == YES ? UTEOptionOpenRemindIncall : UTEOptionCloseRemindIncall];
        LWLog(@"【UTE】*** 【旧版】来电提醒设置:  %@",  sendCallRemindComand ? @"成功" : @"失败");
        BOOL sendQQRemindComand = [[UTESmartBandClient sharedInstance] setUTEOption:setting.call == YES ? UTEOptionOpenRemindQQ : UTEOptionCloseRemindQQ];
        LWLog(@"【UTE】*** 【旧版】QQ提醒设置:  %@",  sendQQRemindComand ? @"成功" : @"失败");
        BOOL sendWeChatRemindComand = [[UTESmartBandClient sharedInstance] setUTEOption:setting.call == YES ? UTEOptionOpenRemindWeixin : UTEOptionCloseRemindWeixin];
        LWLog(@"【UTE】*** 【旧版】微信提醒设置:  %@",  sendWeChatRemindComand ? @"成功" : @"失败");
        BOOL sendSMSRemindComand = [[UTESmartBandClient sharedInstance] setUTEOption:setting.call == YES ? UTEOptionOpenRemindSms : UTEOptionCloseRemindSms];
        LWLog(@"【UTE】*** 【旧版】短信提醒设置:  %@",  sendSMSRemindComand ? @"成功" : @"失败");
        BOOL sendMoreRemindComand = [[UTESmartBandClient sharedInstance] setUTEOption:setting.call == YES ? UTEOptionOpenRemindMore : UTEOptionCloseRemindMore];
        LWLog(@"【UTE】*** 【旧版】其它提醒设置:  %@",  sendMoreRemindComand ? @"成功" : @"失败");
        
        
        if (sendCallRemindComand || sendQQRemindComand || sendWeChatRemindComand || sendSMSRemindComand || sendMoreRemindComand) {
            if (success) {
                success(@(YES));
            }
        }
    }
}

#pragma mark - 【GET】获取常用联系人
/// 获取常用联系人
+ (void)getUTEFavContactsList:(void(^)(id result))success
                   failure:(void(^)(NSError *error))failure {
    
    RLMUTEContactModel *model = [RLMUTEContactModel.allObjects lastObject];
    NSMutableArray *arr = NSMutableArray.array;
    for (RLMUTEContactItemModel *item in model.items) {
        LWPersonModel *model = LWPersonModel.new;
        model.name = item.name;
        model.phoneNumber = item.phone;
        [arr addObject:model];
    }
    
    GCD_MAIN_QUEUE(^{success(arr);});
}

#pragma mark - 【SET】设置常用联系人列表
/// 设置常用联系人列表
+ (void)setUTEFavoriteContactsList:(NSArray *)param
                        success:(void(^)(id result))success
                        failure:(void(^)(NSError *error))failure {
    
    NSMutableArray *arr = NSMutableArray.array;
    for (LWPersonModel *model in param) {
        UTEModelContactInfo *contactModel = UTEModelContactInfo.new;
        contactModel.name = model.name;
        contactModel.number = model.phoneNumber;
        [arr addObject:contactModel];
    }
    
    if (arr.count) {
        BOOL sendComand = [[UTESmartBandClient sharedInstance] sendUTEContactInfo:arr callback:^{
            GCD_MAIN_QUEUE(^{
                
                RLMUTEContactModel *model = RLMUTEContactModel.new;
                model.keyID = LWDeviceInfo.getAppName;
                for (LWPersonModel *person in param) {
                    RLMUTEContactItemModel *item = RLMUTEContactItemModel.new;
                    item.name = person.name;
                    item.phone = person.phoneNumber;
                    [model.items addObject:item];
                }
                
                [RLMRealm.defaultRealm transactionWithBlock:^{
                    [RLMRealm.defaultRealm addOrUpdateObject:model];
                }];
                
                if (success) {
                    success(@(YES));
                }
            });
        }];
        LWLog(@"【UTE】*** 设置常用联系人列表指令发送:%@",  sendComand ? @"成功" : @"失败");
    }
    else {
        BOOL sendComand = [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionDeleteAllContacts];
        LWLog(@"【UTE】*** 删除所有联系人列表指令发送:%@",  sendComand ? @"成功" : @"失败");
        if (sendComand) {
            if (success) {
                success(@(YES));
            }
        } else {
            
        }
    }
}

#pragma mark - 表盘相关
/// 获取当前手表的配置
+ (void)requestGetUTEDialInfo:(void(^)(UTEModelDeviceDisplayModel *localDisplayModel))success
                      failure:(void(^)(NSError *error))failure {
    [[UTESmartBandClient sharedInstance] readUTEDisplayInfoFormDevice:^(UTEModelDeviceDisplayModel * _Nullable model) {
        if (success) {
            success(model);
        }
    }];
}

#pragma mark - 获取UTE设备支持的运动
/// 获取UTE设备支持的运动
- (void)readUTESportModelSupportWithBlock:(void(^)(NSInteger minDisplay, NSInteger maxDisplay, NSArray<NSNumber *> * _Nullable array))success
                                  failure:(void(^)(NSError *error))failure {
    [[UTESmartBandClient sharedInstance] readUTESportModelSupport:^(NSInteger minDisplay, NSInteger maxDisplay, NSArray<NSNumber *> * _Nullable array) {
        LWLog(@"设备:%@ 当前界面上显示的运动图标的最小数量:%ld 最大数据量:%ld", [UTESmartBandClient sharedInstance].connectedDevicesModel.name, minDisplay, maxDisplay);
        if (success) {
            success(minDisplay,maxDisplay,array);
        }
    }];
}

#pragma mark - 获取UTE设备当前显示的运动
/// 获取UTE设备当前显示的运动
- (void)readUTESportModelCurrentDisplayWithBlock:(void(^)(NSArray<NSNumber *> * _Nullable array))success
                                         failure:(void(^)(NSError *error))failure {
    WeakSelf(self);
    [[UTESmartBandClient sharedInstance] readUTESportModelCurrentDisplay:^(NSArray<NSNumber *> * _Nullable array) {
        LWLog(@"设备%@当前显示的运动:%@",[UTESmartBandClient sharedInstance].connectedDevicesModel.name, array);
        [weakSelf.sportPushArrM removeAllObjects];
        for (int i = 0; i < array.count; i++) {
            [weakSelf UTESportCodeConversionToLinWearSportCode:[array[i] integerValue]];
            [weakSelf.sportPushArrM addObject:array[i]];
        }
    }];
}

#pragma mark - 更改UTE设备当前显示的运动
/// 更改UTE设备当前显示的运动
- (void)setUTESportModelCurrentDisplay:(LWSportType)sportType
                               success:(void(^)(id result))success
                               failure:(void(^)(NSError *error))failure {
    
//    // 这里的都是测试代码
//    // SDK目前 运动推送 一次只能推送替换5个
//
//    NSInteger sportArrCount = self.sportPushArrM.count / 5;
//    if (sportArrCount == 1) {
//        sportArrCount = 0;
//    }
//    else {
//        sportArrCount = self.sportPushArrM.count - 5;
//    }
//
//    for (int i = 1; i <= sportArrCount; i++) {
//        [self.sportPushArrM removeLastObject];
//    }
    
    if (!self.sportPushArrM.count) { // 避免下面替换越界奔溃
        LWLog(@"数组错误拦截，避免下面替换越界奔溃");
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:500 userInfo:@{@"message":LWLocalizbleString(@"运动推送失败，请稍后再试")}];
            failure(error);
        }
        return;
    }
    
    [self.sportPushArrM replaceObjectAtIndex:self.sportPushArrM.count-1 withObject:[NSNumber numberWithInteger:[self LinWearSportCodeConversionToUTESportCode:sportType]]];
    
    if (self.sportPushArrM.count) {
        LWLog(@"要推送的到手表上的运动是%@", self.sportPushArrM);
        
        BOOL sportPushStatus = [[UTESmartBandClient sharedInstance] setUTESportModelCurrentDisplay:self.sportPushArrM callback:^(BOOL succeed, NSInteger errorCode) {
            
            LWLog(@"推送结果是: %@", success ? @"成功" : @"失败");
            GCD_MAIN_QUEUE(^{
                if (succeed) {
                    if (success) {
                        success(@(succeed));
                    }
                } else {
                    if (failure) {
                        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:errorCode userInfo:@{@"message":LWLocalizbleString(@"运动推送失败，请稍后再试")}];
                        failure(error);
                    }
                }
            });
        }];
        
        LWLog(@"运动推送的指令发送: %@", sportPushStatus ? @"成功了" : @"失败了");
        
        LWLog(@"UTE version: %@", [UTESmartBandClient sharedInstance].connectedDevicesModel.version);
    }
}

#pragma mark - UTE设备GPS运动状态控制
/// UTE设备GPS运动状态控制
- (void)setUTESportModel:(LWGPSMotionTempModel *)model
                 success:(void(^)(id result))success
                 failure:(void(^)(NSError *error))failure {
    
    UTEDeviceSportMode mode = UTEDeviceSportModeNone;
    if (model.SportType == LWSportOutdoorRun) {
        mode = UTEDeviceSportModeRunning;
    } else if (model.SportType == LWSportIndoorRun) {
        mode = UTEDeviceSportModeIndoorRunning;
    } else if (model.SportType == LWSportOutdoorWalk) {
        mode = UTEDeviceSportModeWalking;
    } else if (model.SportType == LWSportOutdoorCycle) {
        mode = UTEDeviceSportModeCycling;
    }
    
    BOOL seedSuccess = NO;
    if (model.MotionState==LWGPSMotionState_Start || model.MotionState==LWGPSMotionState_End)
    {
        BOOL open;
        if (model.MotionState == LWGPSMotionState_Start) { // 开始
            open = YES;
        } else { // 结束
            open = NO;
        }
        seedSuccess = [UTESmartBandClient.sharedInstance setUTESportModel:mode open:open hrmTime:UTEDeviceIntervalTime10s callback:^(UTEDeviceSportMode mode, BOOL open) {
//            if (success) {
//                success(@(YES));
//            }
        }];
    }
    else if (model.MotionState==LWGPSMotionState_Pause || model.MotionState==LWGPSMotionState_Resume)
    {
        UTEDeviceSportModeInfo *modelInfo = UTEDeviceSportModeInfo.new;
        modelInfo.mode = mode;
        //CN:其他值，把app的数据赋值发下去给设备
        //EN:Other values, assign app data to the device
        modelInfo.calories = model.calorie;
        modelInfo.distance = model.distance;
        modelInfo.duration = model.realTime;
        modelInfo.speed = model.avgPace;
        modelInfo.hrmTime = UTEDeviceIntervalTime10s;
        
        if (model.MotionState == LWGPSMotionState_Pause) // 暂停
        {
            modelInfo.status = UTEDeviceSportModeStatusPause;
            seedSuccess = [UTESmartBandClient.sharedInstance setUTESportModelPause:modelInfo];
        }
        else // 继续
        {
            modelInfo.status = UTEDeviceSportModeStatusContinue;
            seedSuccess = [UTESmartBandClient.sharedInstance setUTESportModelContinue:modelInfo];
        }
    }
    
    LWLog(@"GPS运动控制指令发送: %@", seedSuccess ? @"成功了" : @"失败了");
    if (seedSuccess)
    {
        if (success) {
            success(@(YES));
        }
    }
    else
    {
        NSError *error = [NSError errorWithDomain:LWLocalizbleString(@"同步失败") code:404 userInfo:@{NSLocalizedDescriptionKey:LWLocalizbleString(@"同步失败")}];
        if (failure) {
            failure(error);
        }
    }
}

#pragma mark - UTE设备GPS运动数据交流
///UTE设备GPS运动数据交流
- (void)setUTESportModelInfo:(LWGPSMotionTempModel *)model
                     success:(void(^)(id result))success
                     failure:(void(^)(NSError *error))failure {
    
    UTEDeviceSportMode mode = UTEDeviceSportModeNone;
    if (model.SportType == LWSportOutdoorRun) {
        mode = UTEDeviceSportModeRunning;
    } else if (model.SportType == LWSportIndoorRun) {
        mode = UTEDeviceSportModeIndoorRunning;
    } else if (model.SportType == LWSportOutdoorWalk) {
        mode = UTEDeviceSportModeWalking;
    } else if (model.SportType == LWSportOutdoorCycle) {
        mode = UTEDeviceSportModeCycling;
    }
    
    UTEDeviceSportModeStatus status = UTEDeviceSportModeStatusContinue;
    if (model.MotionState == LWGPSMotionState_Start) {
        status = UTEDeviceSportModeStatusOpen;
    } else if (model.MotionState == LWGPSMotionState_End) {
        status = UTEDeviceSportModeStatusClose;
    } else if (model.MotionState == LWGPSMotionState_Pause) {
        status = UTEDeviceSportModeStatusPause;
    } else if (model.MotionState == LWGPSMotionState_Resume) {
        status = UTEDeviceSportModeStatusContinue;
    }
    
    UTEDeviceSportModeInfo *modeInfo = UTEDeviceSportModeInfo.new;
    modeInfo.mode = mode;
    modeInfo.status = status;
    modeInfo.hrmTime = UTEDeviceIntervalTime10s;
    modeInfo.duration = model.realTime;
    modeInfo.calories = model.calorie;
    modeInfo.distance = model.distance;
    modeInfo.speed = model.avgPace; // 这里有歧义，app设计骑行为时速，其他为配速，UTE协议只有速度（配速）
    
    BOOL seedSuccess = [UTESmartBandClient.sharedInstance setUTESportModelInfo:modeInfo];
    
    LWLog(@"GPS运动数据交流指令发送: %@", seedSuccess ? @"成功了" : @"失败了");
    
    if (seedSuccess)
    {
        if (success) {
            success(@(YES));
        }
    }
    else
    {
        NSError *error = [NSError errorWithDomain:LWLocalizbleString(@"同步失败") code:404 userInfo:@{NSLocalizedDescriptionKey:LWLocalizbleString(@"同步失败")}];
        if (failure) {
            failure(error);
        }
    }
}

#pragma mark - 将 UTE SDK 返回的运动 Code 转换成 LinWear 自己维护的运动 Code
/// 将 UTE SDK 返回的运动 Code 转换成 LinWear 自己维护的运动 Code
- (NSInteger)LinWearSportCodeConversionToUTESportCode:(NSInteger)type {
    
    LWLog(@"服务器返回的运动类型 %ld", type);
    
    UTEDeviceSportMode sportType;
    
    switch (type) {
        case LWSportOutdoorRun:
            LWLog(@"UTEDeviceSportModeRunning");
            sportType = UTEDeviceSportModeRunning;
            break;
        case LWSportIndoorWalk:
            LWLog(@"UTEDeviceSportModeIndoorWalking");
            sportType = UTEDeviceSportModeIndoorWalking;
            break;
        case LWSportOutdoorCycle:
            LWLog(@"UTEDeviceSportModeCycling");
            sportType = UTEDeviceSportModeCycling;
            break;
        case LWSportIndoorRun:
            LWLog(@"UTEDeviceSportModeIndoorRunning");
            sportType = UTEDeviceSportModeIndoorRunning;
            break;
        case LWSportStrengthTraining:
            LWLog(@"UTEDeviceSportModeStrengthTraining");
            sportType = UTEDeviceSportModeStrengthTraining;
            break;
        case LWSportFootball:
            LWLog(@"UTEDeviceSportModeSoccer_USA");
            sportType = UTEDeviceSportModeSoccer_USA;
            break;
        case LWSportStepTraining:
            LWLog(@"UTEDeviceSportModeStepping");
            sportType = UTEDeviceSportModeStepping;
            break;
        case LWSportHorseRiding:
            LWLog(@"UTEDeviceSportModeHorseRiding");
            sportType = UTEDeviceSportModeHorseRiding;
            break;
        case LWSportHockey:
            LWLog(@"UTEDeviceSportModeHockey");
            sportType = UTEDeviceSportModeHockey;
            break;
        case LWSportTableTennis:
            LWLog(@"UTEDeviceSportModeTableTennis");
            sportType = UTEDeviceSportModeTableTennis;
            break;
        case LWSportBadminton:
            LWLog(@"UTEDeviceSportModeBadminton");
            sportType = UTEDeviceSportModeBadminton;
            break;
        case LWSportIndoorCycle:
            LWLog(@"UTEDeviceSportModeSpinningCycling");
            sportType = UTEDeviceSportModeSpinningCycling;
            break;
        case LWSportEllipticaltrainer:
            LWLog(@"UTEDeviceSportModeEllipticalTrainer");
            sportType = UTEDeviceSportModeEllipticalTrainer;
            break;
        case LWSportYoga:
            LWLog(@"UTEDeviceSportModeYoga");
            sportType = UTEDeviceSportModeYoga;
            break;
        case LWSportCricket:
            LWLog(@"UTEDeviceSportModeCricket");
            sportType = UTEDeviceSportModeCricket;
            break;
        case LWSportTaiChi:
            LWLog(@"UTEDeviceSportModeTaiChi");
            sportType = UTEDeviceSportModeTaiChi;
            break;
        case LWSportShuttlecock:
            LWLog(@"UTEDeviceSportModeShuttlecock");
            sportType = UTEDeviceSportModeShuttlecock;
            break;
        case LWSportBoxing:
            LWLog(@"UTEDeviceSportModeBoxing");
            sportType = UTEDeviceSportModeBoxing;
            break;
        case LWSportBasketball:
            LWLog(@"UTEDeviceSportModeBasketball");
            sportType = UTEDeviceSportModeBasketball;
            break;
        case LWSportOutdoorWalk:
            LWLog(@"UTEDeviceSportModeOutdoorWalking");
            sportType = UTEDeviceSportModeOutdoorWalking;
            break;
        case LWSportMountaineering:
            LWLog(@"UTEDeviceSportModeMountaineering");
            sportType = UTEDeviceSportModeMountaineering;
            break;
        case LWSportTrailRunning:
            LWLog(@"UTEDeviceSportModeTrailRunning");
            sportType = UTEDeviceSportModeTrailRunning;
            break;
        case LWSportSkiing:
            LWLog(@"UTEDeviceSportModeSkiing");
            sportType = UTEDeviceSportModeSkiing;
            break;
        case LWSportFreeTraining:
            LWLog(@"UTEDeviceSportModeFree");
            sportType = UTEDeviceSportModeFree;
            break;
        case LWSportGymnastics:
            LWLog(@"UTEDeviceSportModeGymnastics");
            sportType = UTEDeviceSportModeGymnastics;
            break;
        case LWSportIceHockey:
            LWLog(@"UTEDeviceSportModeIceHockey");
            sportType = UTEDeviceSportModeIceHockey;
            break;
        case LWSportTaekwondo:
            LWLog(@"UTEDeviceSportModeTaekwondo");
            sportType = UTEDeviceSportModeTaekwondo;
            break;
        case LWSportVO2maxTest:
            LWLog(@"UTEDeviceSportModeVO2maxTest");
            sportType = UTEDeviceSportModeVO2maxTest;
            break;
        case LWSportRowingMaching:
            LWLog(@"UTEDeviceSportModeRowingMachine");
            sportType = UTEDeviceSportModeRowingMachine;
            break;
        case LWSportAirWalker:
            LWLog(@"UTEDeviceSportModeWalkingMachine");
            sportType = UTEDeviceSportModeWalkingMachine;
            break;
        case LWSportHiking:
            LWLog(@"UTEDeviceSportModeWalking");
            sportType = UTEDeviceSportModeWalking;
            break;
        case LWSportTennis:
            LWLog(@"UTEDeviceSportModeTennis");
            sportType = UTEDeviceSportModeTennis;
            break;
        case LWSportDance:
            LWLog(@"UTEDeviceSportModeDance");
            sportType = UTEDeviceSportModeDance;
            break;
        case LWSportAthletics:
            LWLog(@"UTEDeviceSportModeAthletics");
            sportType = UTEDeviceSportModeAthletics;
            break;
        case LWSportWaisttraining:
            LWLog(@"UTEDeviceSportModeWaistTraining");
            sportType = UTEDeviceSportModeWaistTraining;
            break;
        case LWSportKarate:
            LWLog(@"UTEDeviceSportModeKarate");
            sportType = UTEDeviceSportModeKarate;
            break;
        case LWSportCooldown:
            LWLog(@"UTEDeviceSportModeCoolDown");
            sportType = UTEDeviceSportModeCoolDown;
            break;
        case LWSportCrossTraining:
            LWLog(@"UTEDeviceSportModeCrossTraining");
            sportType = UTEDeviceSportModeCrossTraining;
            break;
        case LWSportPilates:
            LWLog(@"UTEDeviceSportModePilates");
            sportType = UTEDeviceSportModePilates;
            break;
        case LWSportCrossFit:
            LWLog(@"UTEDeviceSportModeCrossFit");
            sportType = UTEDeviceSportModeCrossFit;
            break;
        case LWSportFunctionalTraining:
            LWLog(@"UTEDeviceSportModeFunctionalTraining");
            sportType = UTEDeviceSportModeFunctionalTraining;
            break;
        case LWSportPhysicalTraining:
            LWLog(@"UTEDeviceSportModePhysicalTraining");
            sportType = UTEDeviceSportModePhysicalTraining;
            break;
        case LWSportJumpRope:
            LWLog(@"UTEDeviceSportModeRopeSkipping");
            sportType = UTEDeviceSportModeRopeSkipping;
            break;
        case LWSportArchery:
            LWLog(@"UTEDeviceSportModeArchery");
            sportType = UTEDeviceSportModeArchery;
            break;
        case LWSportFlexibility:
            LWLog(@"UTEDeviceSportModeFlexibility");
            sportType = UTEDeviceSportModeFlexibility;
            break;
        case LWSportMixedCardio:
            LWLog(@"UTEDeviceSportModeMixedCardio");
            sportType = UTEDeviceSportModeMixedCardio;
            break;
        case LWSportLatinDance:
            LWLog(@"UTEDeviceSportModeLatinDance");
            sportType = UTEDeviceSportModeLatinDance;
            break;
        case LWSportStreetDance:
            LWLog(@"UTEDeviceSportModeStreetDance");
            sportType = UTEDeviceSportModeStreetDance;
            break;
        case LWSportKickboxing:
            LWLog(@"UTEDeviceSportModeKickboxing");
            sportType = UTEDeviceSportModeKickboxing;
            break;
        case LWSportBarre:
            LWLog(@"UTEDeviceSportModeBarre");
            sportType = UTEDeviceSportModeBarre;
            break;
        case LWSportAustralianFootball:
            LWLog(@"UTEDeviceSportModeAustralianFootball");
            sportType = UTEDeviceSportModeAustralianFootball;
            break;
        case LWSportMartialArts:
            LWLog(@"UTEDeviceSportModeMartialArts");
            sportType = UTEDeviceSportModeMartialArts;
            break;
        case LWSportStairs:
            LWLog(@"UTEDeviceSportModeClimbStairs");
            sportType = UTEDeviceSportModeClimbStairs;
            break;
        case LWSportHandball:
            LWLog(@"UTEDeviceSportModeHandball");
            sportType = UTEDeviceSportModeHandball;
            break;
        case LWSportBaseball:
            LWLog(@"UTEDeviceSportModeBaseball");
            sportType = UTEDeviceSportModeBaseball;
            break;
        case LWSportBowling:
            LWLog(@"UTEDeviceSportModeBowling");
            sportType = UTEDeviceSportModeBowling;
            break;
        case LWSportRacquetball:
            LWLog(@"UTEDeviceSportModeSquash");
            sportType = UTEDeviceSportModeSquash;
            break;
        case LWSportCurling:
            LWLog(@"UTEDeviceSportModeCurling");
            sportType = UTEDeviceSportModeCurling;
            break;
            //打猎 UTE 不支持 返回的是 0
            //        case UTEDeviceSportModeHunting:
            //            LWLog(@"UTEDeviceSportModeHunting");
            //            sportType = LWSportHunting;
            //            break;
        case LWSportSnowboarding:
            LWLog(@"UTEDeviceSportModeSnowboarding");
            sportType = UTEDeviceSportModeSnowboarding;
            break;
        case LWSportPlay:
            LWLog(@"UTEDeviceSportModeLeisure");
            sportType = UTEDeviceSportModeLeisure;
            break;
        case LWSportAmericanFootball:
            LWLog(@"UTEDeviceSportModeAmericanFootball");
            sportType = UTEDeviceSportModeAmericanFootball;
            break;
        case LWSportHandCycling:
            LWLog(@"UTEDeviceSportModeHandcycling");
            sportType = UTEDeviceSportModeHandcycling;
            break;
        case LWSportFishing:
            LWLog(@"UTEDeviceSportModeFishing");
            sportType = UTEDeviceSportModeFishing;
            break;
        case LWSportDiscSports:
            LWLog(@"UTEDeviceSportModeFrisbee");
            sportType = UTEDeviceSportModeFrisbee;
            break;
        case LWSportRugby:
            LWLog(@"橄榄球 推送ID 15 对应SDK UTEDeviceSportModeFootball_USA");
            sportType = UTEDeviceSportModeFootball_USA; // 橄榄球推送15
            break;
        case LWSportGolf:
            LWLog(@"UTEDeviceSportModeGolf");
            sportType = UTEDeviceSportModeGolf;
            break;
        case LWSportFolkDance:
            LWLog(@"UTEDeviceSportModeFolkDance");
            sportType = UTEDeviceSportModeFolkDance;
            break;
        case LWSportDownhillSkiing:
            LWLog(@"UTEDeviceSportModeDownhillSkiing");
            sportType = UTEDeviceSportModeDownhillSkiing;
            break;
        case LWSportSnowSports:
            LWLog(@"UTEDeviceSportModeSnow_Sports");
            sportType = UTEDeviceSportModeSnow_Sports;
            break;
        case LWSportVolleyball:
            LWLog(@"UTEDeviceSportModeVolleyball");
            sportType = UTEDeviceSportModeVolleyball;
            break;
        case LWSportMind_Body:
            LWLog(@"UTEDeviceSportModeMeditation");
            sportType = UTEDeviceSportModeMeditation;
            break;
        case LWSportCoreTraining:
            LWLog(@"UTEDeviceSportModeCoreTraining");
            sportType = UTEDeviceSportModeCoreTraining;
            break;
        case LWSportSkating:
            LWLog(@"UTEDeviceSportModeSkating");
            sportType = UTEDeviceSportModeSkating;
            break;
        case LWSportFitnessGaming:
            LWLog(@"UTEDeviceSportModeFitnessGame");
            sportType = UTEDeviceSportModeFitnessGame;
            break;
        case LWSportAerobics:
            LWLog(@"UTEDeviceSportModeAerobics");
            sportType = UTEDeviceSportModeAerobics;
            break;
        case LWSportGroupTraining:
            LWLog(@"UTEDeviceSportModeGroupGymnastics");
            sportType = UTEDeviceSportModeGroupGymnastics;
            break;
        case LWSportKendo:
            LWLog(@"UTEDeviceSportModeKickboxingGymnastics");
            sportType = UTEDeviceSportModeKickboxingGymnastics;
            break;
        case LWSportLacrosse:
            LWLog(@"UTEDeviceSportModeLacrosse");
            sportType = UTEDeviceSportModeLacrosse;
            break;
        case LWSportRolling:
            LWLog(@"UTEDeviceSportModeFoamRoller");
            sportType = UTEDeviceSportModeFoamRoller;
            break;
        case LWSportWrestling:
            LWLog(@"UTEDeviceSportModeWrestling");
            sportType = UTEDeviceSportModeWrestling;
            break;
        case LWSportFencing:
            LWLog(@"UTEDeviceSportModeFencing");
            sportType = UTEDeviceSportModeFencing;
            break;
        case LWSportSoftball:
            LWLog(@"UTEDeviceSportModeSoftball");
            sportType = UTEDeviceSportModeSoftball;
            break;
        case LWSportSingleBar:
            LWLog(@"UTEDeviceSportModeHorizontalBar");
            sportType = UTEDeviceSportModeHorizontalBar;
            break;
        case LWSportParallelBars:
            LWLog(@"UTEDeviceSportModeParallelBars");
            sportType = UTEDeviceSportModeParallelBars;
            break;
        case LWSportRollerSkating:
            LWLog(@"UTEDeviceSportModeRollerSkating");
            sportType = UTEDeviceSportModeRollerSkating;
            break;
        case LWSportHulaHoop:
            LWLog(@"UTEDeviceSportModeHulaHoop");
            sportType = UTEDeviceSportModeHulaHoop;
            break;
        case LWSportDarts:
            LWLog(@"UTEDeviceSportModeDarts");
            sportType = UTEDeviceSportModeDarts;
            break;
        case LWSportPickleball:
            LWLog(@"UTEDeviceSportModePickleball");
            sportType = UTEDeviceSportModePickleball;
            break;
        case LWSportSitup:
            LWLog(@"UTEDeviceSportModeSit_Ups");
            sportType = UTEDeviceSportModeSit_Ups;
            break;
        case LWSportHIIT:
            LWLog(@"UTEDeviceSportModeHIIT");
            sportType = UTEDeviceSportModeHIIT;
            break;
        case LWSportswim:
            LWLog(@"UTEDeviceSportModeSwimming");
            sportType = UTEDeviceSportModeSwimming;
            break;
        case LWSportTreadmill:
            LWLog(@"UTEDeviceSportModeTreadmill");
            sportType = UTEDeviceSportModeTreadmill;
            break;
        case LWSportBoating:
            LWLog(@"UTEDeviceSportModeBoating");
            sportType = UTEDeviceSportModeBoating;
            break;
        case LWSportShooting:
            LWLog(@"UTEDeviceSportModeShoot");
            sportType = UTEDeviceSportModeShoot;
            break;
        case LWSportJudo:
            LWLog(@"UTEDeviceSportModeJudo");
            sportType = UTEDeviceSportModeJudo;
            break;
        case LWSportTrampoline:
            LWLog(@"UTEDeviceSportModeTrampoline");
            sportType = UTEDeviceSportModeTrampoline;
            break;
        case LWSportSkateboarding:
            LWLog(@"UTEDeviceSportModeSkateboard");
            sportType = UTEDeviceSportModeSkateboard;
            break;
        case LWSportHoverboard:
            LWLog(@"UTEDeviceSportModeHoverboard");
            sportType = UTEDeviceSportModeHoverboard;
            break;
        case LWSportBlading:
            LWLog(@"UTEDeviceSportModeBlading");
            sportType = UTEDeviceSportModeBlading;
            break;
        case LWSportParkour:
            LWLog(@"UTEDeviceSportModeParkour");
            sportType = UTEDeviceSportModeParkour;
            break;
        case LWSportDiving:
            LWLog(@"UTEDeviceSportModeDiving");
            sportType = UTEDeviceSportModeDiving;
            break;
        case LWSportSurfing:
            LWLog(@"UTEDeviceSportModeSurfing");
            sportType = UTEDeviceSportModeSurfing;
            break;
        case LWSportSnorkeling:
            LWLog(@"UTEDeviceSportModeSnorkeling");
            sportType = UTEDeviceSportModeSnorkeling;
            break;
        case LWSportPull_up:
            LWLog(@"UTEDeviceSportModePull_ups");
            sportType = UTEDeviceSportModePull_ups;
            break;
        case LWSportPush_up:
            LWLog(@"UTEDeviceSportModePush_ups");
            sportType = UTEDeviceSportModePush_ups;
            break;
        case LWSportPlanking:
            LWLog(@"UTEDeviceSportModePlank");
            sportType = UTEDeviceSportModePlank;
            break;
        case LWSportRockClimbing:
            LWLog(@"UTEDeviceSportModeRockClimbing");
            sportType = UTEDeviceSportModeRockClimbing;
            break;
        case LWSportHightjump:
            LWLog(@"UTEDeviceSportModeHighJump");
            sportType = UTEDeviceSportModeHighJump;
            break;
        case LWSportBungeeJumping:
            LWLog(@"UTEDeviceSportModeBungeeJumping");
            sportType = UTEDeviceSportModeBungeeJumping;
            break;
        case LWSportLongjump:
            LWLog(@"UTEDeviceSportModeLongJump");
            sportType = UTEDeviceSportModeLongJump;
            break;
        case LWSportMarathon:
            LWLog(@"UTEDeviceSportModeMarathon");
            sportType = UTEDeviceSportModeMarathon;
            break;
            
        default:
            sportType = UTEDeviceSportModeNone;
            break;
    }
    
    LWLog(@"处理后推送给手表的运动类型 %ld", sportType);
    
    return sportType;
}

- (NSInteger)UTESportCodeConversionToLinWearSportCode:(NSInteger)type {
    
    LWLog(@"SDK 返回的运动类型 %ld", type);
    
    LWSportType sportType;
    
    switch (type) {
        case UTEDeviceSportModeRunning:
            LWLog(@"UTEDeviceSportModeRunning");
            sportType = LWSportOutdoorRun;
            break;
        case UTEDeviceSportModeIndoorWalking:
            LWLog(@"UTEDeviceSportModeIndoorWalking");
            sportType = LWSportIndoorWalk;
            break;
        case UTEDeviceSportModeCycling:
            LWLog(@"UTEDeviceSportModeCycling");
            sportType = LWSportOutdoorCycle;
            break;
        case UTEDeviceSportModeIndoorRunning:
            LWLog(@"UTEDeviceSportModeIndoorRunning");
            sportType = LWSportIndoorRun;
            break;
        case UTEDeviceSportModeStrengthTraining:
            LWLog(@"UTEDeviceSportModeStrengthTraining");
            sportType = LWSportStrengthTraining;
            break;
        case UTEDeviceSportModeSoccer_USA:
            LWLog(@"UTEDeviceSportModeSoccer_USA");
            sportType = LWSportFootball;
            break;
        case UTEDeviceSportModeStepping:
            LWLog(@"UTEDeviceSportModeStepping");
            sportType = LWSportStepTraining;
            break;
        case UTEDeviceSportModeHorseRiding:
            LWLog(@"UTEDeviceSportModeHorseRiding");
            sportType = LWSportHorseRiding;
            break;
        case UTEDeviceSportModeHockey:
            LWLog(@"UTEDeviceSportModeHockey");
            sportType = LWSportHockey;
            break;
        case UTEDeviceSportModeTableTennis:
            LWLog(@"UTEDeviceSportModeTableTennis");
            sportType = LWSportTableTennis;
            break;
        case UTEDeviceSportModeBadminton:
            LWLog(@"UTEDeviceSportModeBadminton");
            sportType = LWSportBadminton;
            break;
        case UTEDeviceSportModeSpinningCycling:
            LWLog(@"UTEDeviceSportModeSpinningCycling");
            sportType = LWSportIndoorCycle;
            break;
        case UTEDeviceSportModeEllipticalTrainer:
            LWLog(@"UTEDeviceSportModeEllipticalTrainer");
            sportType = LWSportEllipticaltrainer;
            break;
        case UTEDeviceSportModeYoga:
            LWLog(@"UTEDeviceSportModeYoga");
            sportType = LWSportYoga;
            break;
        case UTEDeviceSportModeCricket:
            LWLog(@"UTEDeviceSportModeCricket");
            sportType = LWSportCricket;
            break;
        case UTEDeviceSportModeTaiChi:
            LWLog(@"UTEDeviceSportModeTaiChi");
            sportType = LWSportTaiChi;
            break;
        case UTEDeviceSportModeShuttlecock:
            LWLog(@"UTEDeviceSportModeShuttlecock");
            sportType = LWSportShuttlecock;
            break;
        case UTEDeviceSportModeBoxing:
            LWLog(@"UTEDeviceSportModeBoxing");
            sportType = LWSportBoxing;
            break;
        case UTEDeviceSportModeBasketball:
            LWLog(@"UTEDeviceSportModeBasketball");
            sportType = LWSportBasketball;
            break;
        case UTEDeviceSportModeOutdoorWalking:
            LWLog(@"UTEDeviceSportModeOutdoorWalking");
            sportType = LWSportOutdoorWalk;
            break;
        case UTEDeviceSportModeMountaineering:
            LWLog(@"UTEDeviceSportModeMountaineering");
            sportType = LWSportMountaineering;
            break;
        case UTEDeviceSportModeTrailRunning:
            LWLog(@"UTEDeviceSportModeTrailRunning");
            sportType = LWSportTrailRunning;
            break;
        case UTEDeviceSportModeSkiing:
            LWLog(@"UTEDeviceSportModeSkiing");
            sportType = LWSportSkiing;
            break;
        case UTEDeviceSportModeFree:
            LWLog(@"UTEDeviceSportModeFree");
            sportType = LWSportFreeTraining;
            break;
        case UTEDeviceSportModeGymnastics:
            LWLog(@"UTEDeviceSportModeGymnastics");
            sportType = LWSportGymnastics;
            break;
        case UTEDeviceSportModeIceHockey:
            LWLog(@"UTEDeviceSportModeIceHockey");
            sportType = LWSportIceHockey;
            break;
        case UTEDeviceSportModeTaekwondo:
            LWLog(@"UTEDeviceSportModeTaekwondo");
            sportType = LWSportTaekwondo;
            break;
        case UTEDeviceSportModeVO2maxTest:
            LWLog(@"UTEDeviceSportModeVO2maxTest");
            sportType = LWSportVO2maxTest;
            break;
        case UTEDeviceSportModeRowingMachine:
            LWLog(@"UTEDeviceSportModeRowingMachine");
            sportType = LWSportRowingMaching;
            break;
        case UTEDeviceSportModeWalkingMachine:
            LWLog(@"UTEDeviceSportModeWalkingMachine");
            sportType = LWSportAirWalker;
            break;
        case UTEDeviceSportModeWalking:
            LWLog(@"UTEDeviceSportModeWalking");
            sportType = LWSportHiking;
            break;
        case UTEDeviceSportModeTennis:
            LWLog(@"UTEDeviceSportModeTennis");
            sportType = LWSportTennis;
            break;
        case UTEDeviceSportModeDance:
            LWLog(@"UTEDeviceSportModeDance");
            sportType = LWSportDance;
            break;
        case UTEDeviceSportModeAthletics:
            LWLog(@"UTEDeviceSportModeAthletics");
            sportType = LWSportAthletics;
            break;
        case UTEDeviceSportModeWaistTraining:
            LWLog(@"UTEDeviceSportModeWaistTraining");
            sportType = LWSportWaisttraining;
            break;
        case UTEDeviceSportModeKarate:
            LWLog(@"UTEDeviceSportModeKarate");
            sportType = LWSportKarate;
            break;
        case UTEDeviceSportModeCoolDown:
            LWLog(@"UTEDeviceSportModeCoolDown");
            sportType = LWSportCooldown;
            break;
        case UTEDeviceSportModeCrossTraining:
            LWLog(@"UTEDeviceSportModeCrossTraining");
            sportType = LWSportCrossTraining;
            break;
        case UTEDeviceSportModePilates:
            LWLog(@"UTEDeviceSportModePilates");
            sportType = LWSportPilates;
            break;
        case UTEDeviceSportModeCrossFit:
            LWLog(@"UTEDeviceSportModeCrossFit");
            sportType = LWSportCrossFit;
            break;
        case UTEDeviceSportModeFunctionalTraining:
            LWLog(@"UTEDeviceSportModeFunctionalTraining");
            sportType = LWSportFunctionalTraining;
            break;
        case UTEDeviceSportModePhysicalTraining:
            LWLog(@"UTEDeviceSportModePhysicalTraining");
            sportType = LWSportPhysicalTraining;
            break;
        case UTEDeviceSportModeRopeSkipping:
            LWLog(@"UTEDeviceSportModeRopeSkipping");
            sportType = LWSportJumpRope;
            break;
        case UTEDeviceSportModeArchery:
            LWLog(@"UTEDeviceSportModeArchery");
            sportType = LWSportArchery;
            break;
        case UTEDeviceSportModeFlexibility:
            LWLog(@"UTEDeviceSportModeFlexibility");
            sportType = LWSportFlexibility;
            break;
        case UTEDeviceSportModeMixedCardio:
            LWLog(@"UTEDeviceSportModeMixedCardio");
            sportType = LWSportMixedCardio;
            break;
        case UTEDeviceSportModeLatinDance:
            LWLog(@"UTEDeviceSportModeLatinDance");
            sportType = LWSportLatinDance;
            break;
        case UTEDeviceSportModeStreetDance:
            LWLog(@"UTEDeviceSportModeStreetDance");
            sportType = LWSportStreetDance;
            break;
        case UTEDeviceSportModeKickboxing:
            LWLog(@"UTEDeviceSportModeKickboxing");
            sportType = LWSportKickboxing;
            break;
        case UTEDeviceSportModeBarre:
            LWLog(@"UTEDeviceSportModeBarre");
            sportType = LWSportBarre;
            break;
        case UTEDeviceSportModeAustralianFootball:
            LWLog(@"UTEDeviceSportModeAustralianFootball");
            sportType = LWSportAustralianFootball;
            break;
        case UTEDeviceSportModeMartialArts:
            LWLog(@"UTEDeviceSportModeMartialArts");
            sportType = LWSportMartialArts;
            break;
        case UTEDeviceSportModeClimbStairs:
            LWLog(@"UTEDeviceSportModeClimbStairs");
            sportType = LWSportStairs;
            break;
        case UTEDeviceSportModeHandball:
            LWLog(@"UTEDeviceSportModeHandball");
            sportType = LWSportHandball;
            break;
        case UTEDeviceSportModeBaseball:
            LWLog(@"UTEDeviceSportModeBaseball");
            sportType = LWSportBaseball;
            break;
        case UTEDeviceSportModeBowling:
            LWLog(@"UTEDeviceSportModeBowling");
            sportType = LWSportBowling;
            break;
        case UTEDeviceSportModeSquash:
            LWLog(@"UTEDeviceSportModeSquash");
            sportType = LWSportRacquetball;
            break;
        case UTEDeviceSportModeCurling:
            LWLog(@"UTEDeviceSportModeCurling");
            sportType = LWSportCurling;
            break;
            //打猎 UTE 不支持 返回的是 0
            //        case UTEDeviceSportModeHunting:
            //            LWLog(@"UTEDeviceSportModeHunting");
            //            sportType = LWSportHunting;
            //            break;
        case UTEDeviceSportModeSnowboarding:
            LWLog(@"UTEDeviceSportModeSnowboarding");
            sportType = LWSportSnowboarding;
            break;
        case UTEDeviceSportModeLeisure:
            LWLog(@"UTEDeviceSportModeLeisure");
            sportType = LWSportPlay;
            break;
        case UTEDeviceSportModeAmericanFootball:
            LWLog(@"UTEDeviceSportModeAmericanFootball");
            sportType = LWSportAmericanFootball;
            break;
        case UTEDeviceSportModeHandcycling:
            LWLog(@"UTEDeviceSportModeHandcycling");
            sportType = LWSportHandCycling;
            break;
        case UTEDeviceSportModeFishing:
            LWLog(@"UTEDeviceSportModeFishing");
            sportType = LWSportFishing;
            break;
        case UTEDeviceSportModeFrisbee:
            LWLog(@"UTEDeviceSportModeFrisbee");
            sportType = LWSportDiscSports;
            break;
        case UTEDeviceSportModeRugby:
            LWLog(@"UTEDeviceSportModeRugby");
            sportType = LWSportRugby;
            break;
        case UTEDeviceSportModeGolf:
            LWLog(@"UTEDeviceSportModeGolf");
            sportType = LWSportGolf;
            break;
        case UTEDeviceSportModeFolkDance:
            LWLog(@"UTEDeviceSportModeFolkDance");
            sportType = LWSportFolkDance;
            break;
        case UTEDeviceSportModeDownhillSkiing:
            LWLog(@"UTEDeviceSportModeDownhillSkiing");
            sportType = LWSportDownhillSkiing;
            break;
        case UTEDeviceSportModeSnow_Sports:
            LWLog(@"UTEDeviceSportModeSnow_Sports");
            sportType = LWSportSnowSports;
            break;
        case UTEDeviceSportModeVolleyball:
            LWLog(@"UTEDeviceSportModeVolleyball");
            sportType = LWSportVolleyball;
            break;
        case UTEDeviceSportModeMeditation:
            LWLog(@"UTEDeviceSportModeMeditation");
            sportType = LWSportMind_Body;
            break;
        case UTEDeviceSportModeCoreTraining:
            LWLog(@"UTEDeviceSportModeCoreTraining");
            sportType = LWSportCoreTraining;
            break;
        case UTEDeviceSportModeSkating:
            LWLog(@"UTEDeviceSportModeSkating");
            sportType = LWSportSkating;
            break;
        case UTEDeviceSportModeFitnessGame:
            LWLog(@"UTEDeviceSportModeFitnessGame");
            sportType = LWSportFitnessGaming;
            break;
        case UTEDeviceSportModeAerobics:
            LWLog(@"UTEDeviceSportModeAerobics");
            sportType = LWSportAerobics;
            break;
        case UTEDeviceSportModeGroupGymnastics:
            LWLog(@"UTEDeviceSportModeGroupGymnastics");
            sportType = LWSportGroupTraining;
            break;
        case UTEDeviceSportModeKickboxingGymnastics:
            LWLog(@"UTEDeviceSportModeKickboxingGymnastics");
            sportType = LWSportKendo;
            break;
        case UTEDeviceSportModeLacrosse:
            LWLog(@"UTEDeviceSportModeLacrosse");
            sportType = LWSportLacrosse;
            break;
        case UTEDeviceSportModeFoamRoller:
            LWLog(@"UTEDeviceSportModeFoamRoller");
            sportType = LWSportRolling;
            break;
        case UTEDeviceSportModeWrestling:
            LWLog(@"UTEDeviceSportModeWrestling");
            sportType = LWSportWrestling;
            break;
        case UTEDeviceSportModeFencing:
            LWLog(@"UTEDeviceSportModeFencing");
            sportType = LWSportFencing;
            break;
        case UTEDeviceSportModeSoftball:
            LWLog(@"UTEDeviceSportModeSoftball");
            sportType = LWSportSoftball;
            break;
        case UTEDeviceSportModeHorizontalBar:
            LWLog(@"UTEDeviceSportModeHorizontalBar");
            sportType = LWSportSingleBar;
            break;
        case UTEDeviceSportModeParallelBars:
            LWLog(@"UTEDeviceSportModeParallelBars");
            sportType = LWSportParallelBars;
            break;
        case UTEDeviceSportModeRollerSkating:
            LWLog(@"UTEDeviceSportModeRollerSkating");
            sportType = LWSportRollerSkating;
            break;
        case UTEDeviceSportModeHulaHoop:
            LWLog(@"UTEDeviceSportModeHulaHoop");
            sportType = LWSportHulaHoop;
            break;
        case UTEDeviceSportModeDarts:
            LWLog(@"UTEDeviceSportModeDarts");
            sportType = LWSportDarts;
            break;
        case UTEDeviceSportModePickleball:
            LWLog(@"UTEDeviceSportModePickleball");
            sportType = LWSportPickleball;
            break;
        case UTEDeviceSportModeSit_Ups:
            LWLog(@"UTEDeviceSportModeSit_Ups");
            sportType = LWSportSitup;
            break;
        case UTEDeviceSportModeHIIT:
            LWLog(@"UTEDeviceSportModeHIIT");
            sportType = LWSportHIIT;
            break;
        case UTEDeviceSportModeSwimming:
            LWLog(@"UTEDeviceSportModeSwimming");
            sportType = LWSportswim;
            break;
        case UTEDeviceSportModeTreadmill:
            LWLog(@"UTEDeviceSportModeTreadmill");
            sportType = LWSportTreadmill;
            break;
        case UTEDeviceSportModeBoating:
            LWLog(@"UTEDeviceSportModeBoating");
            sportType = LWSportBoating;
            break;
        case UTEDeviceSportModeShoot:
            LWLog(@"UTEDeviceSportModeShoot");
            sportType = LWSportShooting;
            break;
        case UTEDeviceSportModeJudo:
            LWLog(@"UTEDeviceSportModeJudo");
            sportType = LWSportJudo;
            break;
        case UTEDeviceSportModeTrampoline:
            LWLog(@"UTEDeviceSportModeTrampoline");
            sportType = LWSportTrampoline;
            break;
        case UTEDeviceSportModeSkateboard:
            LWLog(@"UTEDeviceSportModeSkateboard");
            sportType = LWSportSkateboarding;
            break;
        case UTEDeviceSportModeHoverboard:
            LWLog(@"UTEDeviceSportModeHoverboard");
            sportType = LWSportHoverboard;
            break;
        case UTEDeviceSportModeBlading:
            LWLog(@"UTEDeviceSportModeBlading");
            sportType = LWSportBlading;
            break;
        case UTEDeviceSportModeParkour:
            LWLog(@"UTEDeviceSportModeParkour");
            sportType = LWSportParkour;
            break;
        case UTEDeviceSportModeDiving:
            LWLog(@"UTEDeviceSportModeDiving");
            sportType = LWSportDiving;
            break;
        case UTEDeviceSportModeSurfing:
            LWLog(@"UTEDeviceSportModeSurfing");
            sportType = LWSportSurfing;
            break;
        case UTEDeviceSportModeSnorkeling:
            LWLog(@"UTEDeviceSportModeSnorkeling");
            sportType = LWSportSnorkeling;
            break;
        case UTEDeviceSportModePull_ups:
            LWLog(@"UTEDeviceSportModePull_ups");
            sportType = LWSportPull_up;
            break;
        case UTEDeviceSportModePush_ups:
            LWLog(@"UTEDeviceSportModePush_ups");
            sportType = LWSportPush_up;
            break;
        case UTEDeviceSportModePlank:
            LWLog(@"UTEDeviceSportModePlank");
            sportType = LWSportPlanking;
            break;
        case UTEDeviceSportModeRockClimbing:
            LWLog(@"UTEDeviceSportModeRockClimbing");
            sportType = LWSportRockClimbing;
            break;
        case UTEDeviceSportModeHighJump:
            LWLog(@"UTEDeviceSportModeHighJump");
            sportType = LWSportHightjump;
            break;
        case UTEDeviceSportModeBungeeJumping:
            LWLog(@"UTEDeviceSportModeBungeeJumping");
            sportType = LWSportBungeeJumping;
            break;
        case UTEDeviceSportModeLongJump:
            LWLog(@"UTEDeviceSportModeLongJump");
            sportType = LWSportLongjump;
            break;
        case UTEDeviceSportModeMarathon:
            LWLog(@"UTEDeviceSportModeMarathon");
            sportType = LWSportMarathon;
            break;
            
        default:
            sportType = LWSportFreeTraining;
            break;
    }
    
    //    LWLog(@"处理后对应的本地运动类型 %ld", sportType);
    
    return sportType;
}

#pragma mark - GPS运动状态变更
- (void)uteManagerReceiveSportMode:(UTEDeviceSportModeInfo *)info {
    LWLog(@"【UTE】*** 收到手表GPS互联实时运动状态变更%@", info.mj_keyValues);
    if (info) {
        NSDictionary *modeiInfo = @{@"UTE_Kit" : info};
        [NSNotificationCenter.defaultCenter postNotificationName:LWWatchMotionStateUpdateNotification object:nil userInfo:modeiInfo];
    }
}

#pragma mark - GPS运动心率值返回
- (void)uteManagerReceiveSportHRM:(NSDictionary *)dict {
    LWLog(@"【UTE】*** 收到手表GPS互联实时运动数据%@", dict);
    if (dict) {
        UTEModelSportHRMData *sportHRMData = dict[@"kUTEQuerySportHRMData"];
        if ([sportHRMData isKindOfClass:UTEModelSportHRMData.class] && sportHRMData) {
            LWLog(@"【UTE】*** UTE收到手表GPS互联实时运动数据解析结果: %@", sportHRMData.mj_keyValues);
            NSDictionary *info = @{@"UTE_Kit" : sportHRMData};
            [NSNotificationCenter.defaultCenter postNotificationName:LWWatchMotionDataUpdateNotification object:nil userInfo:info];
        }
    }
}

#pragma mark - block回调去刷新页面
- (void)reloads {
    GCD_MAIN_QUEUE(^{
        // 如果当前在首页，实时刷新页面
        if (UTEBLEDeviceManager.defaultManager.subscriptionHistoryDataBlock && [JTool.getTopMostController isKindOfClass:LWMainHomeViewController.class]) {
            UTEBLEDeviceManager.defaultManager.subscriptionHistoryDataBlock(@(YES));
        }
    });
}

#pragma mark - 手动同步历史运动健康数据
/// 手动同步历史运动健康数据
+ (void)requestUTEHistorySportsHealthData:(void(^)(CGFloat progress, NSString *tip))progressBlcok
                               success:(void(^)(id result))success
                                  failure:(void(^)(NSError *error))failure {
    
    UTEBLEDeviceManager.defaultManager.subscriptionHistoryDataBlock = success;

    // 截止时间为当前
    NSInteger end = NSDate.date.timeIntervalSince1970;
    // 开始时间为当前时间 - 7天前 的现在
    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = end - 24 * 60 * 60 * 7;
    }
    //  *  ①Support device to check data status (what data has not been synchronized) || *①支持设备检查数据状态(哪些数据没有同步)
    //  *  Note:If you want to synchronize data, please invoke method syncDataCustomTime:type: || *注意:如果你想同步数据，请调用方法syncDataCustomTime:类型:
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasDataStatus) {
        
        NSDate *syncStepsBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
        NSString *syncStepsTimerStr = [syncStepsBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
        // 同步步数
        BOOL sendComand = [[UTESmartBandClient sharedInstance] syncDataCustomTime:syncStepsTimerStr type:UTEDeviceDataTypeSteps];
        LWLog(@"【UTE】*** 【同步数据】同步步数数据, 开始时间:%@ 发送:%@", syncStepsTimerStr, sendComand ? @"成功" : @"失败");
        
    } else {
        // 同步步数
        [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionSyncAllStepsData];
    }
}


- (void)syncSucess:(NSDictionary *)info {
    NSArray *arrayRun               = info[kUTEQueryRunData];
    NSArray *arraySleep             = info[kUTEQuerySleepData];
    NSArray *arraySleepDayByDay     = info[kUTEQuerySleepDataDayByDay];
    NSArray *arrayHRM               = info[kUTEQuery24HRMData];
    NSArray *arrayBloodOxygen       = info[kUTEQueryBloodOxygenData];
    NSArray *arrayBloodPressure     = info[kUTEQueryBloodData];
    NSArray *arraySport             = info[kUTEQuerySportWalkRunData];
    NSArray *arrayAllSport          = info[kUTEQuerySportHRMData]; // 所有运动
    
    LWLog(@"【UTE】*** 当前同步成功的数据类型 %@", info);
    
//    for (UTEModelRunData *model in arrayRun) {
//        LWLog(@"【UTE】*** normal***time = %@, hourStep = %ld,Total step = %ld , distance = %f ,calorie = %f",model.time, (long)model.hourSteps,(long)model.totalSteps,model.distances,model.calories);
//    }
//    for (UTEModelSportWalkRun *model in arraySport) {
//        LWLog(@"【UTE】*** sport***time = %@,Total step = %ld , walkDistance = %f ,walkCalorie = %f ,runDistance = %f,runCalorie =%f",model.time, (long)model.stepsTotal,model.walkDistances,model.walkCalories,model.runDistances,model.runCalories);
//    }
//    for (UTEModelSleepData *model in arraySleep) {
//        LWLog(@"【UTE】*** start=%@,end=%@,type=%ld",model.startTime,model.endTime,(long)model.sleepType);
//    }
//    for (NSArray *array in arraySleepDayByDay) {
//        for (UTEModelSleepData *model in array) {
//            LWLog(@"【UTE】*** dayByday***start=%@,end=%@,type=%ld",model.startTime,model.endTime,(long)model.sleepType);
//        }
//    }
//    for (UTEModelHRMData *model in arrayHRM) {
//        [self heartDetectingData:model];
//    }
//
//    for (UTEModelBloodData *model in arrayBlood) {
//        [self bloodDetectingData:model];
//    }
    
    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = NSDate.date.timeIntervalSince1970 - 24 * 60 * 60 * 7;
    }
    NSDate *testBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
    NSString *testBeginTimerStr = [testBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
    
    if([[info allKeys] containsObject:kUTEQueryRunData]) {
        for (UTEModelRunData *model in arrayRun) {
            LWLog(@"【UTE】*** normal***time = %@, hourStep = %ld,Total step = %ld , distance = %f ,calorie = %f",model.time, (long)model.hourSteps,(long)model.totalSteps,model.distances,model.calories);
        }
        return;
    }
    
    if([[info allKeys] containsObject:kUTEQuerySleepDataDayByDay]) {
#pragma mark - 优创亿 同步睡眠
        if (arraySleepDayByDay.count) {
            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的睡眠数据");
            for (NSArray *array in arraySleepDayByDay) {
                if (array.count) {
                    [self syncUTESleepDetectingData:arraySleep];
                    return;
                }
            }
        } else {
//            LWLog(@"UTE 同步数据  睡眠数据为空  开始同步血氧数据");
//            [[UTESmartBandClient sharedInstance] setUTEOption:(UTEOptionSyncAllBloodOxygenData)];
            LWLog(@"【UTE】*** 同步数据  睡眠数据为空 开始同步心率数据");
            [[UTESmartBandClient sharedInstance] syncDataCustomTime:testBeginTimerStr type:UTEDeviceDataTypeHRM24];
        }
        return;
    }
    
    if([[info allKeys] containsObject:kUTEQuerySportWalkRunData]) {
#pragma mark - 优创亿 同步步数
        if (arraySport.count ) {
            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的运动步数数据");
//            [self syncUTEStepsDetectingData:arraySport];
            GCD_MAIN_QUEUE(^{[self syncUTEStepsDetectingData:arraySport];});
            return;
        } else {
            LWLog(@"【UTE】*** 同步数据  步数数据为空  开始同步睡眠数据");
            [[UTESmartBandClient sharedInstance] syncDataCustomTime:testBeginTimerStr type:UTEDeviceDataTypeSleep];
        }
    }
    
    
    if([[info allKeys] containsObject:kUTEQuery24HRMData]) {
#pragma mark - 优创亿 同步心率
        if (arrayHRM.count) {
            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的心率数据");
            [self syncUTEHeartDetectingData:arrayHRM];
            return;
        } else {
            LWLog(@"【UTE】*** 同步数据  心率数据为空  开始同步血氧数据");
            [[UTESmartBandClient sharedInstance] setUTEOption:(UTEOptionSyncAllBloodOxygenData)];
        }
        return;
    }
    
    
    if([[info allKeys] containsObject:kUTEQuerySportHRMData]) {
#pragma mark - 优创亿 同步所有运动
        if (arrayAllSport.count) {
            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的运动数据");
            [self syncUTEAllSportDetectingData:arrayAllSport];
            return;
        } else {
            LWLog(@"【UTE】*** 同步数据  运动数据为空 结束本次数据刷新请求");
            NSInteger date = NSDate.date.timeIntervalSince1970;
            [NSUserDefaults.standardUserDefaults setInteger:date forKey:LW_HOMEDATA_REFRESHTIME];
            
            [self reloads];
        }
        return;
    }
    
    if([[info allKeys] containsObject:kUTEQueryBloodOxygenData]) {
#pragma mark - 优创亿 同步血氧
        if (arrayBloodOxygen.count) {
            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的血氧数据");
            [self syncUTEBloodOxygenDetectingData:arrayBloodOxygen];
        } else {
            LWLog(@"【UTE】*** 同步数据  血氧数据为空  开始同步运动数据");
            [[UTESmartBandClient sharedInstance] syncUTESportModelCustomTime:testBeginTimerStr];
        }
    }
    
    if([[info allKeys] containsObject:kUTEQueryBloodData]) {
#pragma mark - 优创亿 同步血压
//        if (arrayBloodPressure.count) {
//            LWLog(@"【UTE】*** 同步数据  开始处理设备返回的血压数据");
//            [self syncUTEBloodOxygenDetectingData:arrayBloodOxygen];
//        } else {
//            LWLog(@"【UTE】*** 同步数据  血压数据为空  开始同步运动数据");
//            [[UTESmartBandClient sharedInstance] syncUTESportModelCustomTime:testBeginTimerStr];
//        }
    }
}

- (void)heartDetectingData:(UTEModelHRMData *)model {
    LWLog(@"【UTE】*** heartTime=%@ heartCoun=%@ heartType=%ld",model.heartTime,model.heartCount,(long)model.heartType);
}

- (void)bloodDetectingData:(UTEModelBloodData *)model {
    LWLog(@"【UTE】*** time=%@ bloodSystolic=%@ bloodDiastolic=%@ type=%ld",model.bloodTime,model.bloodSystolic,model.bloodDiastolic,model.bloodType);
}


#pragma mark - 优创亿 步数记录返回
- (void)syncUTEStepsDetectingData:(NSArray *)modelArr {
    LWLog(@"---------【UTE】*** 步数记录---------");

    NSString *bluetoothName = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Name];
    NSString *bluetoothAddress = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Address];
    NSString *bluetoothAdapter = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Adapter];
    
    __block BOOL todaySyncStatus = YES; // 处理今天步数 由于会返回多次今天的数据, 需要一个tag值来记录, 第一次执行删除今天的数据,后续返回今天的数据时,数据库不需要再次删除
    
    NSInteger tempTodySteps = 0;
    NSInteger tempTodyCalories = 0;
    
    if ([modelArr isKindOfClass:[NSArray class]]) {
        
        for (int i = 0; i < modelArr.count; i++) {
            
            UTEModelSportWalkRun *model = modelArr[i];
            
            NSString *stepStartTimeStr = [NSString stringWithFormat:@"%@-%@-00", model.time, model.walkTimeStart];
            NSDate *stepStartDate = [NSDate dateWithString:stepStartTimeStr format:@"yyyy-MM-dd-HH-mm-ss"];
            NSTimeInterval stepStartTimeStamp = [stepStartDate timeIntervalSince1970];
            NSInteger stepStartTime = stepStartTimeStamp;
            
            NSInteger cycle = (model.walkDuration + model.runDuration) * 60; // 持续时间时间(秒)
            
            NSInteger steps = model.stepsTotal; // // 计步数
            NSInteger stepsCreateTime = stepStartTime; // 产生这一条步数的时间戳
            NSInteger stepsCalories = (long)(model.walkCalories * 1000) + (long)(model.runCalories * 1000);
            NSInteger stepsDistance = model.walkDistances * 100 + model.runDistances * 100;
            LWLog(@"【UTE】*** 步数记录 日期:%@ 步数:%ld 距离:%ldm 卡路里:%ldcal 【持续时间:%ldh%ldm%lds】\n🚶开始时间 %@:%@ 步数 %ld 距离 %f 卡路里 %f 持续时间 %ldm\n🏃开始时间 %@:%@ 步数 %ld 距离 %f 卡路里 %f 持续时间 %ldm", stepStartTimeStr, steps, stepsDistance, stepsCalories, cycle/3600, cycle/60, cycle%60, model.time, model.walkTimeStart, model.walkSteps, model.walkDistances, model.walkCalories, model.walkDuration, model.time, model.runTimeStart, model.runSteps, model.runDistances, model.runCalories, model.runDuration);
            
            // 由于优创亿返回的步数是整点 时间是精确到小时
            // APP不好做数据兼容 SDK也不愿意修改
            // 只能通过以下这种方式处理: 即同步今天的步数数据的时候,删除数据库今天的数据,重新写入,这么做可以确保拿到的数据是最新且不会重复写入
            NSString *stepStartTimeString = [NSString stringWithFormat:@"%@", model.time];
            NSDate *stepStartTimeDate = [NSDate dateWithString:stepStartTimeString format:@"yyyy-MM-dd-HH"];
            BOOL isToday = [[NSCalendar currentCalendar] isDateInToday:stepStartTimeDate];
            
            if (isToday) {
                tempTodySteps += steps;
                tempTodyCalories += stepsCalories;
            }
            
            if (steps > 0) {
                
                if (isToday && todaySyncStatus) {
                    LWLog(@"【UTE】***【查询步数数据库】时间条件：【begin >= %zd】 AND 【begin < %zd】",  (NSInteger)(NSDate.date.zeroIntervalOfDate), (NSInteger)(NSDate.date.lastIntervalOfDate));
                    LWLog(@"【UTE】***【查询步数数据库】手表信息条件：【sdkType = %ld】 AND 【watchName = '%@'】 AND 【watchMacAddress = '%@'】", LWDeviceInfo.getCurrentQuerySDKType, LWDeviceInfo.getCurrentQueryWatchName, LWDeviceInfo.getCurrentQueryWatchwatchMac);
                    NSString *sql = [LWTool SQL_queryStart:(NSInteger)(NSDate.date.zeroIntervalOfDate) end:(NSInteger)(NSDate.date.lastIntervalOfDate)];
                    RLMResults *stepResults = [RLMStepModel objectsWhere: sql];

                    BOOL currentSatus = stepResults.invalidated;
                    LWLog(@"是今天, 删除今天的步数数据库 %@ --- (invalidated = %@), 不管是否有效, 实际上都是删除了...", stepResults, currentSatus ? @"有效" : @"无效");
                    if (stepResults.count > 0) {
                        
                        [RLMRealm.defaultRealm transactionWithBlock:^{
                            [RLMRealm.defaultRealm deleteObjects:stepResults];
                        }];
                        
                        // 运动
                        RLMResults *sportsArray = [RLMSportsModel objectsWhere: sql];
                        LWLog(@"【UTE】*** 🍊当天运动数据库的数组有%ld组",sportsArray.count);
                        
                        NSInteger sportSteps = 0;
                        NSInteger sportDistances = 0;
                        NSInteger sportCalorys = 0;
                        
                        for (int i = 0; i < sportsArray.count; i++) {
                            
                            RLMSportsModel *sportModel = sportsArray[i];
                            
                            RLMStepModel *model = RLMStepModel.new;
                            model.begin = sportModel.begin;
                            model.interval = sportModel.interval;
                            model.steps = sportModel.steps;
                            model.calory = sportModel.calories;
                            model.distance = sportModel.distance * 100; // SportsModel的距离是m，需要转换成cm
                            model.sdkType = UTESDK;
                            model.watchName = sportModel.watchName;
                            model.watchMacAddress = sportModel.watchMacAddress;
                            model.watchAdapter = sportModel.watchAdapter;
                            
                            sportSteps = model.steps;
                            sportDistances = model.distance;
                            sportCalorys = model.calory;
                            
                            [RLMRealm.defaultRealm transactionWithBlock:^{
                                [RLMRealm.defaultRealm addObject:model];
                            }];
                        }
                        LWLog(@"【UTE】*** 🍊当天运动数据库的总步数为%ld 距离是%ld 卡路里是%ld",sportSteps, sportDistances, sportCalorys);
                        
                        todaySyncStatus = NO;
                    }
                }
                
                RLMStepModel *model = RLMStepModel.new;
                model.begin = stepsCreateTime;
                model.interval = cycle;
                model.steps = steps;
                model.calory = stepsCalories;
                model.distance = stepsDistance;
                model.sdkType = UTESDK;
                model.watchName = bluetoothName;
                model.watchMacAddress = bluetoothAddress;
                model.watchAdapter = bluetoothAdapter;

                LWLog(@"【UTE】*** %@ 的步数为%ld 距离是%ld 卡路里是%ld", stepStartTimeStr, model.steps, model.distance, model.calory);
                
                [RLMRealm.defaultRealm transactionWithBlock:^{
                    [RLMRealm.defaultRealm addObject:model];
                }];
            }
        }
    }
    
    LWLog(@"🎆🎆🎆🎆🎆 【UTE】*** 今日总步数: %ld 总卡路里:%ld", tempTodySteps, tempTodyCalories/1000);
    
    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = NSDate.date.timeIntervalSince1970 - 24 * 60 * 60 * 7;
    }
    NSDate *testBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
    NSString *testBeginTimerStr = [testBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
    [[UTESmartBandClient sharedInstance] syncDataCustomTime:testBeginTimerStr type:UTEDeviceDataTypeSleep];
    LWLog(@"【UTE】*** 步数数据同步完成后, 发起同步睡眠 - %@", testBeginTimerStr);
}

#pragma mark - 优创亿 运动记录返回
- (void)syncUTEAllSportDetectingData:(NSArray *)sportsDataArray {
    LWLog(@"---------【UTE】*** 运动记录---------");
    
    NSString *bluetoothName = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Name];
    NSString *bluetoothAddress = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Address];
    NSString *bluetoothAdapter = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Adapter];
    
    RLMResults *sportsArray = [RLMSportsModel.allObjects sortedResultsUsingKeyPath:@"begin" ascending:YES]; // 对查询结果排序
    RLMSportsModel *sportsModel = sportsArray.lastObject; // 最新的一条运动数据

    NSDate *sportDate = NSDate.new;
    
    for (int i = 0; i < sportsDataArray.count; i++) {
        
        UTEModelSportHRMData *sportModel = sportsDataArray[i];
        
        NSDate *date = [NSDate dateWithString:sportModel.timeStart format:@"yyyy-MM-dd-HH-mm-ss"];
        NSTimeInterval timeStamp = [date timeIntervalSince1970];
        NSInteger beginTime = timeStamp;
        sportDate = date;
        
        NSDate *endDate = [NSDate dateWithString:sportModel.timeEnd format:@"yyyy-MM-dd-HH-mm-ss"];
        NSTimeInterval endTimeStamp = [endDate timeIntervalSince1970];
        NSInteger endTime = endTimeStamp;
        
        LWLog(@"\n------【UTE】*** 同步运动记录------\n当前运动类型 - %ld\n当前运动开始时间 - %@\n当前运动结束时间 - %@\n当前运动总距离 - %ld米\n当前运动总卡路里 - %ld卡\n当前运动总步数 - %ld\n",
              [[UTEBLEDeviceManager defaultManager] UTESportCodeConversionToLinWearSportCode:sportModel.sportModel],
            sportModel.timeStart,
              sportModel.timeEnd,
              (NSInteger)(sportModel.distance * 1000),
              (NSInteger)(sportModel.calories * 1000),
              sportModel.steps);
        
        if ((sportsModel.begin) < beginTime) {
            
            RLMSportsModel *model = RLMSportsModel.new; // 运动
            model.begin = beginTime;
            model.end = endTime;
            model.distance = sportModel.distance * 1000; // UTE这里是km 需要转成 m
            model.calories = sportModel.calories * 1000;
            model.duration = sportModel.validTime; // 优创亿 运动有效时长
            model.steps = sportModel.steps;
            model.interval = sportModel.hrmInterval;
            model.sportHR = sportModel.hrmAve;
            model.sportType = [[UTEBLEDeviceManager defaultManager] UTESportCodeConversionToLinWearSportCode:sportModel.sportModel];
            model.maxHeartRate = sportModel.hrmMax;
            model.minHeartRate = sportModel.hrmMin;
            model.sdkType = UTESDK;
            model.watchName = bluetoothName;
            model.watchMacAddress = bluetoothAddress;
            model.watchAdapter = bluetoothAdapter;
            
            for (int i = 0; i < sportModel.hrmArray.count; i++) {
                NSInteger detailHRM = [sportModel.hrmArray[i] integerValue];
                if (detailHRM > 0) {
                    RLMSportsItemModel *itemModel = RLMSportsItemModel.new;
                    itemModel.hr_excercise = detailHRM;
                    [model.items addObject:itemModel];
                }
            }
            
//            LWLog(@"\n------【优创亿】同步运动记录------\n当前运动类型 - %ld\n当前运动开始时间 - %ld\n当前运动结束时间 - %ld\n当前运动总距离 - %ld米\n当前运动总卡路里 - %ld卡\n当前运动总步数 - %ld\n",model.sportType, model.begin, model.end, model.distance, model.calories, model.steps);
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addObject:model];
            }];
            
            RLMStepModel *stepModel = RLMStepModel.new;
            stepModel.begin = beginTime;
            stepModel.interval = sportModel.validTime;
            stepModel.steps = sportModel.steps;
            stepModel.calory = sportModel.calories * 1000;
            stepModel.distance = sportModel.distance * 1000 * 100;// UTE这里是km 需要转成 cm
            stepModel.sdkType = UTESDK;
            stepModel.watchName = bluetoothName;
            stepModel.watchMacAddress = bluetoothAddress;
            stepModel.watchAdapter = bluetoothAdapter;
            
            LWLog(@"\n------【UTE】*** 同步运动记录------\n当前运动类型 - %ld\n当前运动开始时间 - %ld\n当前运动结束时间 - %ld\n当前运动总距离 - %ld米\n当前运动总卡路里 - %ld卡\n当前运动总步数 - %ld\n当前运动有效时长 - %ld",model.sportType, model.begin, model.end, model.distance, model.calories, model.steps, model.duration);
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addObject:stepModel];
            }];
        }
    }
    
    NSInteger date = NSDate.date.timeIntervalSince1970;
    [NSUserDefaults.standardUserDefaults setInteger:date forKey:LW_HOMEDATA_REFRESHTIME];
    [self reloads];
    LWLog(@"【UTE】*** 运动数据同步完成后, 结束刷新状态");
}

#pragma mark - 优创亿 睡眠记录返回
- (void)syncUTESleepDetectingData:(NSArray *)sleepDataArray {
    
    NSString *bluetoothName = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Name];
    NSString *bluetoothAddress = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Address];
    NSString *bluetoothAdapter = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Adapter];
    
    LWLog(@"---------【UTE】*** 睡眠记录---------");
    LWLog(@"【优创亿】【查询睡眠数据库】手表信息条件：【sdkType = %ld】 AND 【watchName = '%@'】 AND 【watchMacAddress = '%@'】", LWDeviceInfo.getCurrentQuerySDKType, LWDeviceInfo.getCurrentQueryWatchName, LWDeviceInfo.getCurrentQueryWatchwatchMac);
    NSString *sleepSql = [LWTool SQL_queryStart:0 end:0]; // 查询条件
    RLMResults *sleepArray = [[RLMSleepModel objectsWhere: sleepSql] sortedResultsUsingKeyPath:@"begin" ascending:YES];
    RLMSleepModel *sleepDataModel = sleepArray.lastObject;// 从数据库中获取的最新的一条数据
    
    for (int i = 0; i < sleepDataArray.count; i++) {
        
        UTEModelSleepData *sleepModel = sleepDataArray[i];
        
        NSDate *sleepBeginDate = [NSDate dateWithString:sleepModel.startTime format:@"yyyy-MM-dd-HH-mm"];
        NSTimeInterval sleepBeginTimeStamp = [sleepBeginDate timeIntervalSince1970];
        NSInteger beginRecordTime = sleepBeginTimeStamp;
        
        NSDate *sleepEndDate = [NSDate dateWithString:sleepModel.endTime format:@"yyyy-MM-dd-HH-mm"];
        NSTimeInterval sleepEndTimeStamp = [sleepEndDate timeIntervalSince1970];
        NSInteger endRecordTime = sleepEndTimeStamp;
        
        LWLog(@"【UTE】*** 睡眠记录 开始日期:%@ 结束日期:%@ 睡眠状态:%ld(0:清醒 1:深睡 2:浅睡 4:眼动 5:小睡)", sleepModel.startTime, sleepModel.endTime, sleepModel.sleepType);
        
        if (endRecordTime > (sleepDataModel.begin + sleepDataModel.interval)) {
            RLMSleepModel *model = RLMSleepModel.new;
            model.begin = beginRecordTime;
            model.interval = endRecordTime - beginRecordTime;
            model.sdkType = UTESDK;
            model.watchName = bluetoothName;
            model.watchMacAddress = bluetoothAddress;
            model.watchAdapter = bluetoothAdapter;
            
            switch (sleepModel.sleepType) {
                case UTESleepTypeAwake: { // 清醒
                    model.quality = 0x03;
                }
                    break;
                case UTESleepTypeLightSleep: { // 浅睡
                    model.quality = model.quality = 0x02;
                }
                    break;
                case UTESleepTypeDeepSleep: { // 深睡
                    model.quality = model.quality = 0x01;
                }
                    break;
                case UTESleepTypeSleepREM: { // 眼动
                    model.quality = model.quality = 0x04;
                }
                    break;
                case UTESleepTypeSleepSporadic: { // 零星小睡
                    model.quality = 0x05;
                }
                    break;
                default:
                    break;
            }
            LWLog(@"【UTE】*** 🐑写入数据库【UTE】睡眠记录 开始日期:%@ 结束日期:%@ 睡眠状态:%ld(0:清醒 1:深睡 2:浅睡 4:眼动 5:小睡)", sleepModel.startTime, sleepModel.endTime, sleepModel.sleepType);
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addObject:model];
            }];
        }
    }
    
    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = NSDate.date.timeIntervalSince1970 - 24 * 60 * 60 * 7;
    }
    NSDate *testBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
    NSString *testBeginTimerStr = [testBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
    if ([UTESmartBandClient sharedInstance].connectedDevicesModel.isHasDataStatus) {
        LWLog(@"【UTE】*** 睡眠数据同步完成后, 发起同步心率 - %@", testBeginTimerStr);
        [[UTESmartBandClient sharedInstance] syncDataCustomTime:testBeginTimerStr type:UTEDeviceDataTypeHRM24];
    } else {
        LWLog(@"【UTE】*** 睡眠数据同步完成后, 调用 UTEOptionSyncAllHRMData 发起同步心率");
        [[UTESmartBandClient sharedInstance] setUTEOption:UTEOptionSyncAllHRMData];
    }
}

#pragma mark - 优创亿 心率记录返回
- (void)syncUTEHeartDetectingData:(NSArray *)heartDataArray {

    NSString *bluetoothName = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Name];
    NSString *bluetoothAddress = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Address];
    NSString *bluetoothAdapter = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Adapter];
    
    LWLog(@"---------【UTE】*** 心率记录---------");
    RLMResults *HRArray = [RLMHeartRateModel.allObjects sortedResultsUsingKeyPath:@"begin" ascending:YES]; // 对查询结果排序
    RLMHeartRateModel *hrModel = HRArray.lastObject;
    
    for (int i = 0; i < heartDataArray.count; i++) {
        
        UTEModelHRMData *heartModel = heartDataArray[i];
        
        NSDate *date = [NSDate dateWithString:heartModel.heartTime format:@"yyyy-MM-dd-HH-mm"];
        NSTimeInterval timeStamp = [date timeIntervalSince1970];
        NSInteger recordTime = timeStamp;
        NSInteger interval = 10 * 60;
        
        LWLog(@"【UTE】*** 心率记录 日期:%@ 心率值:%ld", heartModel.heartTime, [heartModel.heartCount integerValue]);
        
        if ( ([heartModel.heartCount integerValue] > 0 )&& (hrModel.begin + 1) < recordTime) {
            
            RLMHeartRateModel *model = RLMHeartRateModel.new;
            model.begin = recordTime;
            model.value = [heartModel.heartCount integerValue];
            model.interval = interval;
            model.sdkType = UTESDK;
            model.watchName = bluetoothName;
            model.watchMacAddress = bluetoothAddress;
            model.watchAdapter = bluetoothAdapter;
            
            [RLMRealm.defaultRealm transactionWithBlock:^{
                [RLMRealm.defaultRealm addObject:model];
            }];
        }
    }

    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = NSDate.date.timeIntervalSince1970 - 24 * 60 * 60 * 7;
    }
    NSDate *testBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
    NSString *testBeginTimerStr = [testBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
    [[UTESmartBandClient sharedInstance] setUTEOption:(UTEOptionSyncAllBloodOxygenData)];
    LWLog(@"【UTE】*** 心率数据同步完成后, 发起同步血氧 - %@", testBeginTimerStr);
}


#pragma mark - 优创亿 血氧记录返回
- (void)syncUTEBloodOxygenDetectingData:(NSArray *)bloodOxygenDataArr {
    
    LWLog(@"---------【UTE】*** 血氧记录---------");
    NSString *bluetoothName = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Name];
    NSString *bluetoothAddress = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Address];
    NSString *bluetoothAdapter = [NSUserDefaults.standardUserDefaults objectForKey:LW_DEVICE_Adapter];
    
    RLMResults *BOArray = [RLMBloodOxygenModel.allObjects sortedResultsUsingKeyPath:@"begin" ascending:YES]; // 对查询结果排序
    RLMBloodOxygenModel *BOModel = BOArray.lastObject;
    
    for (int i = 0; i < bloodOxygenDataArr.count; i++) {
        
        UTEModelBloodOxygenData *bloodOxygenModel = bloodOxygenDataArr[i];
        
        NSDate *date = [NSDate dateWithString:bloodOxygenModel.time format:@"yyyy-MM-dd-HH-mm"];
        NSTimeInterval timeStamp = [date timeIntervalSince1970];
        NSInteger recordTime = timeStamp;
        NSInteger interval = 10 * 60;
        if (bloodOxygenModel.type == UTEBloodOxygenTypeNormal || bloodOxygenModel.type == UTEBloodOxygenTypeSuccess) {
            LWLog(@"【UTE】*** 血氧记录 日期:%@ 血氧值:%ld%%", bloodOxygenModel.time, bloodOxygenModel.value);
            
            if ( (bloodOxygenModel.value > 0) && (BOModel.begin + 1) < recordTime) {
                
                RLMBloodOxygenModel *model = RLMBloodOxygenModel.new;
                model.begin = recordTime;
                model.value = bloodOxygenModel.value;
                model.interval = interval;
                model.sdkType = UTESDK;
                model.watchName = bluetoothName;
                model.watchMacAddress = bluetoothAddress;
                model.watchAdapter = bluetoothAdapter;
                
                [RLMRealm.defaultRealm transactionWithBlock:^{
                    [RLMRealm.defaultRealm addObject:model];
                }];
            }
        }
    }

    NSInteger start = [NSUserDefaults.standardUserDefaults integerForKey:LW_HOMEDATA_REFRESHTIME];
    if (start == 0) {
        start = NSDate.date.timeIntervalSince1970 - 24 * 60 * 60 * 7;
    }
    NSDate *testBeginTimerDate = [NSDate dateWithTimeIntervalSince1970:(start)];
    NSString *testBeginTimerStr = [testBeginTimerDate stringWithFormat:@"yyyy-MM-dd-HH-mm"];
    BOOL statusSuccess = [[UTESmartBandClient sharedInstance] syncUTESportModelCustomTime:testBeginTimerStr];
    LWLog(@"【UTE】*** 血氧数据同步完成后, 发起同步运动:%@ - %@", statusSuccess?@"成功":@"失败", testBeginTimerStr);
}


- (void)uteManagerReceiveTodaySport:(NSDictionary *)dict {
    UTEModelSportWalkRun *walk = dict[kUTEQuerySportWalkRunData];
    LWLog(@"【UTE】*** 实时步数 sport device step=%ld",(long)walk.stepsTotal);
}

- (void)uteManagerReceiveTodaySteps:(UTEModelRunData *)runData {
    LWLog(@"【UTE】*** 总步数 = %ld",runData.totalSteps);
}

@end
