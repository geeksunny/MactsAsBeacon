//
//  CMAppDelegate.h
//  ActsAsBeacon
//
//  Created by Tim on 11/11/2013.
//  Copyright (c) 2013 Charismatic Megafauna Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMAppDelegate : NSObject <NSApplicationDelegate> {
    NSUserDefaults *prefrences;
}

extern NSString *const PREFS_KEY_UUID;
extern NSString *const PREFS_KEY_MAJOR;
extern NSString *const PREFS_KEY_MINOR;
extern NSString *const PREFS_KEY_POWER;

@property (assign) IBOutlet NSWindow *window;

@end
