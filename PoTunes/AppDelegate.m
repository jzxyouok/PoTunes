//
//  AppDelegate.m
//  PoTunes
//
//  Created by Purchas on 15/9/1.
//  Copyright © 2015年 Purchas. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "WXApi.h"
#import <MAMapKit/MAMapKit.h>
#import <UserNotifications/UserNotifications.h>
#import "XGPush.h"
#import "XGSetting.h"
#import "Debug.h"
//#import "MBProgressHUD+MJ.h"
@interface AppDelegate ()<WXApiDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) int bgTime;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backIdentifier;

@property (nonatomic, assign) BOOL isDownloading;


@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [NSThread sleepForTimeInterval:1];
    
    //设置音乐后台播放的会话类型
    AVAudioSession *session = [AVAudioSession sharedInstance];
	
	[session setActive:YES error:nil];
	
	[session setCategory:AVAudioSessionCategoryPlayback error:nil];

    // 接受远程事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	
	[self becomeFirstResponder];
	
    //向微信注册
    [WXApi registerApp:@"wx0fc8d0673ec86694"];
	
	
	// 后台下载注册
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center addObserver:self selector:@selector(percent:) name:@"percent" object:nil];
	
	[center addObserver:self selector:@selector(complete:) name:@"downloadComplete" object:nil];
	
	// 注册推送
	[[XGSetting getInstance] enableDebug:YES];
	[XGPush startApp:2200248301 appKey:@"I6ZG8X127DEV"];
	
	[XGPush isPushOn:^(BOOL isPushOn) {
		NSSLog(@"[XGDemo] Push Is %@", isPushOn ? @"ON" : @"OFF");
	}];
	
	[self registerAPNS];
	
	[XGPush handleLaunching:launchOptions successCallback:^{
		NSSLog(@"[XGDemo] Handle launching success");
	} errorCallback:^{
		NSSLog(@"[XGDemo] Handle launching error");
	}];

    return YES;
}

- (void)registerAPNS {
	float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (sysVer >= 10) {
		// iOS 10
		[self registerPush10];
	} else if (sysVer >= 9) {
		// iOS 8-9
		[self registerPush8to9];
	}

}

- (void)registerPush10{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
	
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	
	center.delegate = self;
	
	
	[center requestAuthorizationWithOptions:UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
		if (granted) {
		}
	}];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

- (void)registerPush8to9{
	UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
	UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
	[[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)percent:(NSNotification *)sender {
	
	self.isDownloading = 1;
	
}

- (void)complete:(NSNotification *)sender {
	
	self.isDownloading = 0;
	
}


// 此方法是 用户点击了通知，应用在前台 或者开启后台并且应用在后台 时调起
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	NSSLog(@"[XGDemo] receive slient Notification");
	NSSLog(@"[XGDemo] userinfo %@", userInfo);
	[XGPush handleReceiveNotification:userInfo
					  successCallback:^{
						  NSSLog(@"[XGDemo] Handle receive success");
					  } errorCallback:^{
						  NSSLog(@"[XGDemo] Handle receive error");
					  }];
	
	completionHandler(UIBackgroundFetchResultNewData);
 }


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	
	NSString *deviceTokenStr = [XGPush registerDevice:deviceToken account:@"lastshrek" successCallback:^{
		NSSLog(@"[XGDemo] register push success");
	} errorCallback:^{
		NSSLog(@"[XGDemo] register push error");
	}];
	NSSLog(@"[XGDemo] device token is %@", deviceTokenStr);
	
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	
	NSSLog(@"[XGDemo] register APNS fail.\n[XGDemo] reason : %@", error);

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	NSSLog(@"[XGDemo] receive Notification");
	[XGPush handleReceiveNotification:userInfo
					  successCallback:^{
						  NSSLog(@"[XGDemo] Handle receive success");
					  } errorCallback:^{
						  NSSLog(@"[XGDemo] Handle receive error");
					  }];
}

// iOS 10 新增 API
// iOS 10 会走新 API, iOS 10 以前会走到老 API
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// App 用户点击通知的回调
// 无论本地推送还是远程推送都会走这个回调
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler {
	NSSLog(@"[XGDemo] click notification");
	[XGPush handleReceiveNotification:response.notification.request.content.userInfo
					  successCallback:^{
						  NSSLog(@"[XGDemo] Handle receive success");
					  } errorCallback:^{
						  NSSLog(@"[XGDemo] Handle receive error");
					  }];
	
	completionHandler();
}

// App 在前台弹通知需要调用这个接口
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
	
	completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}
#endif


//重写AppDelegate的handleOpenURL和openURL方法：

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation {
    
    return [WXApi handleOpenURL:url delegate:self];
}

- (void)onReq:(BaseReq*)req {
    
}

- (void) onResp:(BaseResp*)resp {
    
    if([resp isKindOfClass:[SendMessageToWXResp class]]) {
    
        if (resp.errCode == 0) {
        
//            [MBProgressHUD showSuccess:@"分享成功"];
					
        } else {
        
//            [MBProgressHUD showError:@"分享失败"];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    //    [application beginBackgroundTaskWithExpirationHandler:nil];
	
	if (self.isDownloading) {
		
		self.backIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			
			self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(repeatTimer) userInfo:nil repeats:YES];
			
			[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
		
		}];
	}

}

- (void)repeatTimer {
	
	if (self.bgTime > 600) {
	
		[self removeBgTimer];
	
	}

}

- (void)removeBgTimer {

	[self.timer invalidate];
	
	self.bgTime = 0;
	
	[[UIApplication sharedApplication] endBackgroundTask:self.backIdentifier];
	
	self.backIdentifier = UIBackgroundTaskInvalid;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	[self removeBgTimer];

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



@end
