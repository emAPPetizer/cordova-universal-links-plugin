//
//  AppDelegate+CULPlugin.m
//
//  Created by Nikolay Demyankov on 15.09.15.
//

#import "AppDelegate+CULPlugin.h"
#import "CULPlugin.h"
#import <Cordova/CDVPluginNotifications.h>

/**
 *  Plugin name in config.xml
 */
static NSString *const PLUGIN_NAME = @"UniversalLinks";

@implementation AppDelegate (CULPlugin)

/**
 *  cordova-ios 8+ uses CDVSceneDelegate (UIScene lifecycle). Its scene:continueUserActivity:
 *  posts CDVPluginContinueUserActivityNotification instead of UIKit calling
 *  application:continueUserActivity:restorationHandler: below directly, so that method is dead
 *  code on cordova-ios 8+ unless something forwards the notification to it. Register here via
 *  +load (runs at process launch, before any scene/delegate is wired up) and replay through the
 *  existing method so CULPlugin still gets a chance to handle the Universal Link.
 */
+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserverForName:CDVPluginContinueUserActivityNotification
                                                       object:nil
                                                        queue:nil
                                                   usingBlock:^(NSNotification *notification) {
        NSUserActivity *userActivity = notification.object;
        if (![userActivity isKindOfClass:[NSUserActivity class]]) {
            return;
        }

        id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
        if (![delegate respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
            return;
        }

        [delegate application:[UIApplication sharedApplication]
          continueUserActivity:userActivity
            restorationHandler:^(NSArray *restorableObjects) {}];
    }];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    // ignore activities that are not for Universal Links
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] || userActivity.webpageURL == nil) {
        return NO;
    }
    
    // get instance of the plugin and let it handle the userActivity object
    CULPlugin *plugin = [self.viewController getCommandInstance:PLUGIN_NAME];
    if (plugin == nil) {
        return NO;
    }
    
    return [plugin handleUserActivity:userActivity];
}

@end
