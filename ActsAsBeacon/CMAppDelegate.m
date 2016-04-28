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

@property (nonatomic) BOOL isBroadcasting;

@end

NSString *const PREFS_KEY_UUID = @"uuid";
NSString *const PREFS_KEY_MAJOR = @"major";
NSString *const PREFS_KEY_MINOR = @"minor";
NSString *const PREFS_KEY_POWER = @"power";

@implementation CMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    prefrences = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"B0702880-A295-A8AB-F734-031A98A512DE", PREFS_KEY_UUID,
                              @"5", PREFS_KEY_MAJOR,
                              @"1000", PREFS_KEY_MINOR,
                              @"-58", PREFS_KEY_POWER,
                              nil];
    [prefrences registerDefaults:defaults];

    // Insert code here to initialize your application
    self.manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    self.isBroadcasting = NO;
    [self.statusField setStringValue:@"Not broadcasting"];
    
}

//- (void)applicationWillTerminate:(NSNotification *)notification {
//    [prefrences synchronize];
//}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        
        self.manager = peripheral;
        
//        NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:@"B0702880-A295-A8AB-F734-031A98A512DE"];
//        CMBeaconAdvertismentData *beaconData = [[CMBeaconAdvertismentData alloc] initWithProximityUUID:proximityUUID major:5 minor:5000 measuredPower:-58];
//        [peripheral startAdvertising:beaconData.beaconAdvertisement];
        
    }
}

- (IBAction)didTapToggleButton:(id)sender {
    
    if (self.manager && !self.isBroadcasting) {
        NSArray<CMBeaconAdvertismentData *> *beacons = [self createBeaconArray];
        
        for (int i = 0; i < [beacons count]; i++) {
            // TODO: This only advertises the last beaconAdvertisement fed in to it.
            //       Look in to a queue system.
            CMBeaconAdvertismentData *beacon = [beacons objectAtIndex:i];
            [self.manager startAdvertising:beacon.beaconAdvertisement];
        }
        self.isBroadcasting = YES;
        
        [self.statusField setStringValue:@"Broadcasting"];
        [self.toggleButton setTitle:@"Stop broadcasting"];
        
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
        [self.statusField setStringValue:@"Not broadcasting"];
        
        self.isBroadcasting = NO;
        [self.toggleButton setTitle:@"Start broadcasting"];

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

    int numOfBeacons = [self largestValue:[NSArray arrayWithObjects:
                                           [NSNumber numberWithUnsignedInteger:[uuids count]],
                                           [NSNumber numberWithUnsignedInteger:[majors count]],
                                           [NSNumber numberWithUnsignedInteger:[minors count]],
                                           [NSNumber numberWithUnsignedInteger:[powers count]],
                                           nil]];

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
        CMBeaconAdvertismentData *beacon = [[CMBeaconAdvertismentData alloc] initWithProximityUUID:uuid major:[major integerValue] minor:[minor integerValue] measuredPower:[power integerValue]];
        [beaconArray addObject:beacon];
    }

    return beaconArray;
}

- (int)largestValue:(NSArray<NSNumber *> *)values {
    int highestValue = -INFINITY;

    for (int i = 0; i < [values count]; i++) {
        if ((int)[values objectAtIndex:i] > highestValue) {
            highestValue = (int)[values objectAtIndex:i];
        }
    }

    return highestValue;
}

@end
