//
//  CDVSceneDelegate+CULPlugin.m
//

#import <objc/runtime.h>
#import <Cordova/CDVSceneDelegate.h>
#import "CULPlugin.h"

/**
 *  On a cold launch from a Universal Link, UIKit delivers the link in
 *  connectionOptions.userActivities of scene:willConnectToSession:options: rather than calling
 *  scene:continueUserActivity:. CDVSceneDelegate only forwards connectionOptions.URLContexts, so
 *  wrap its implementation to also hand the user activities to CULPlugin.
 */
@implementation CDVSceneDelegate (CULPlugin)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selector = @selector(scene:willConnectToSession:options:);
        Method method = class_getInstanceMethod(self, selector);
        if (method == NULL) {
            return;
        }

        typedef void (*WillConnectIMP)(id, SEL, UIScene *, UISceneSession *, UISceneConnectionOptions *);
        WillConnectIMP original = (WillConnectIMP)method_getImplementation(method);

        method_setImplementation(method, imp_implementationWithBlock(^(id delegate, UIScene *scene, UISceneSession *session, UISceneConnectionOptions *connectionOptions) {
            original(delegate, selector, scene, session, connectionOptions);

            for (NSUserActivity *userActivity in connectionOptions.userActivities) {
                [CULPlugin handleSceneUserActivity:userActivity];
            }
        }));
    });
}

@end
