//
//  CMAppDelegate.m
//  ActsAsBeacon
//
//  Created by Tim on 11/11/2013.
//  Copyright (c) 2013 Charismatic Megafauna Ltd. All rights reserved.
//
//  Forked by Justin on 4/26/2016
//

#import "CMAppDelegate.h"
#import <IOBluetooth/IOBluetooth.h>

@interface CMAppDelegate () <CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *manager;
@property (nonatomic, strong) CBPeripheral *mainPeripheral;

@property (nonatomic, weak) IBOutlet NSTextFieldCell *uuidFieldCell;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *majorFieldCell;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *minorFieldCell;
@property (nonatomic, weak) IBOutlet NSTextFieldCell *powerFieldCell;

@property (nonatomic, weak) IBOutlet NSTextField *statusField;
@property (nonatomic, weak) IBOutlet NSButton *toggleButton;

@property (strong, nonatomic) NSMutableArray<CMBeaconAdvertismentData *> *beacons;

@property (nonatomic) BOOL isBroadcasting;

@end

NSString *const PREFS_KEY_UUID = @"uuid";
NSString *const PREFS_KEY_MAJOR = @"major";
NSString *const PREFS_KEY_MINOR = @"minor";
NSString *const PREFS_KEY_POWER = @"power";

NSString *const DEFAULT_UUID = @"AB73D3E4-CC88-4364-91F3-F3A0ABE96641";
NSString *const DEFAULT_MAJOR = @"2";
NSString *const DEFAULT_MINOR = @"68,91,212";
NSString *const DEFAULT_POWER = @"-58";

NSString *const STRING_BEACONS_ACTIVE = @"Broadcasting";
NSString *const STRING_BEACONS_INACTIVE = @"Not broadcasting";
NSString *const STRING_BUTTON_START = @"Start braodcasting";
NSString *const STRING_BUTTON_STOP = @"Stop broadcasting";

@implementation CMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.beacons = [[NSMutableArray alloc] init];

    prefrences = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              DEFAULT_UUID, PREFS_KEY_UUID,
                              DEFAULT_MAJOR, PREFS_KEY_MAJOR,
                              DEFAULT_MINOR, PREFS_KEY_MINOR,
                              DEFAULT_POWER, PREFS_KEY_POWER,
                              nil];
    [prefrences registerDefaults:defaults];

    currentBeacon = 0;

    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    self.isBroadcasting = NO;
    [self.statusField setStringValue:STRING_BEACONS_INACTIVE];
    
}

//- (void)applicationWillTerminate:(NSNotification *)notification {
//    [prefrences synchronize];
//}

- (void)configureAdvertisingForBeacon:(CMBeaconAdvertismentData *)beacon {
    if (self.manager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"Core Bluetooth is off");
        return;
    }
    [self.manager stopAdvertising];
    NSLog(@"Transmitting beacon | UUID: %@ | Major: %hu | Minor: %hu | Power: %hhd",
          beacon.proximityUUID.UUIDString, beacon.major, beacon.minor, beacon.measuredPower);
    [self.manager startAdvertising:[beacon beaconAdvertisement]];
}

- (void)rotateAdvertising {
    [self configureAdvertisingForBeacon:[self currentBeacon]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (!self.isBroadcasting) {
            [self.manager stopAdvertising];
        } else {
            [self rotateAdvertising];
        }
    });
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        self.manager = peripheral;
    }
}

- (CMBeaconAdvertismentData *)currentBeacon {
    if (currentBeacon >= self.beacons.count) {
        currentBeacon = 0;
    }
    currentBeacon++;
    return [self.beacons objectAtIndex:currentBeacon-1];
}

- (IBAction)didTapToggleButton:(id)sender {
    
    if (self.manager && !self.isBroadcasting) {
        [self.beacons removeAllObjects];
        [self.beacons addObjectsFromArray:[self createBeaconArray]];
        
        self.isBroadcasting = YES;
        [self rotateAdvertising];
        
        [self.statusField setStringValue:STRING_BEACONS_ACTIVE];
        [self.toggleButton setTitle:STRING_BUTTON_STOP];
        
        [self.uuidFieldCell setEditable:NO];
        [self.uuidFieldCell setTextColor:[NSColor lightGrayColor]];
        [self.majorFieldCell setEditable:NO];
        [self.majorFieldCell setTextColor:[NSColor lightGrayColor]];
        [self.minorFieldCell setEditable:NO];
        [self.minorFieldCell setTextColor:[NSColor lightGrayColor]];
        [self.powerFieldCell setEditable:NO];
        [self.powerFieldCell setTextColor:[NSColor lightGrayColor]];
        
    } else if (self.manager && self.isBroadcasting) {
        
        [self.manager stopAdvertising];
        [self.statusField setStringValue:STRING_BEACONS_INACTIVE];
        
        self.isBroadcasting = NO;
        [self.toggleButton setTitle:STRING_BUTTON_START];

        [self.uuidFieldCell setEditable:YES];
        [self.uuidFieldCell setTextColor:[NSColor blackColor]];
        [self.majorFieldCell setEditable:YES];
        [self.majorFieldCell setTextColor:[NSColor blackColor]];
        [self.minorFieldCell setEditable:YES];
        [self.minorFieldCell setTextColor:[NSColor blackColor]];
        [self.powerFieldCell setEditable:YES];
        [self.powerFieldCell setTextColor:[NSColor blackColor]];

    }
    
}

- (NSArray<CMBeaconAdvertismentData *> *)createBeaconArray {
    NSMutableArray<CMBeaconAdvertismentData *> *beaconArray = [[NSMutableArray alloc] init];

    NSArray<NSString *> *uuids = [self.uuidFieldCell.stringValue componentsSeparatedByString:@","];
    NSArray<NSString *> *majors = [self.majorFieldCell.stringValue componentsSeparatedByString:@","];
    NSArray<NSString *> *minors = [self.minorFieldCell.stringValue componentsSeparatedByString:@","];
    NSArray<NSString *> *powers = [self.powerFieldCell.stringValue componentsSeparatedByString:@","];

    NSLog(@"%lu %lu %lu %lu", uuids.count, majors.count, minors.count, powers.count);
    int numOfBeacons = [self largestValue:[NSArray arrayWithObjects:
                                           [NSNumber numberWithUnsignedLong:[uuids count]],
                                           [NSNumber numberWithUnsignedLong:[majors count]],
                                           [NSNumber numberWithUnsignedLong:[minors count]],
                                           [NSNumber numberWithUnsignedLong:[powers count]],
                                           nil]];
    NSLog(@"Num of beacons: %d", numOfBeacons);

    for (int i = 0; i < numOfBeacons; i++) {
        NSString *uuid, *major, *minor, *power;
        // uuid
        if (i < (int)[uuids count]) {
            uuid = [uuids objectAtIndex:i];
        } else {
            uuid = [uuids objectAtIndex:[uuids count]-1];
        }
        // major
        if (i < (int)[majors count]) {
            major = [majors objectAtIndex:i];
        } else {
            major = [majors objectAtIndex:[majors count]-1];
        }
        // minor
        if (i < (int)[minors count]) {
            minor = [minors objectAtIndex:i];
        } else {
            minor = [minors objectAtIndex:[minors count]-1];
        }
        // power
        if (i < (int)[powers count]) {
            power = [powers objectAtIndex:i];
        } else {
            power = [powers objectAtIndex:[powers count]-1];
        }
        // beacon record
        CMBeaconAdvertismentData *beacon = [[CMBeaconAdvertismentData alloc]
                                            initWithProximityUUID:uuid
                                            major:[major integerValue]
                                            minor:[minor integerValue]
                                            measuredPower:[power integerValue]];
        [beaconArray addObject:beacon];
    }

    return beaconArray;
}

- (int)largestValue:(NSArray<NSNumber *> *)values {
    int highestValue = -1;

    for (NSNumber *value in values) {
        //NSLog(@"highest: %d | this one: %d", highestValue, value.intValue);
        if (value.intValue > highestValue) {
            highestValue = value.intValue;
        }
    }

    return highestValue;
}

@end
