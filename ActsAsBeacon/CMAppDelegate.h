//
//  CMAppDelegate.h
//  ActsAsBeacon
//
//  Created by Tim on 11/11/2013.
//  Copyright (c) 2013 Charismatic Megafauna Ltd. All rights reserved.
//
//  Forked by Justin on 4/26/2016
//

#import <Cocoa/Cocoa.h>
#import "CMBeaconAdvertismentData.h"

@interface CMAppDelegate : NSObject <NSApplicationDelegate> {
    NSUserDefaults *prefrences;
}

extern NSString *const PREFS_KEY_UUID;
extern NSString *const PREFS_KEY_MAJOR;
extern NSString *const PREFS_KEY_MINOR;
extern NSString *const PREFS_KEY_POWER;

@property (assign) IBOutlet NSWindow *window;

- (NSArray<CMBeaconAdvertismentData *> *)createBeaconArray;

- (int)largestValue:(NSArray<NSNumber *> *)values;



@end
