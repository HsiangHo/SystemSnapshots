//
//  AppDelegate.m
//  System Snapshots
//
//  Created by Jovi on 12/28/18.
//  Copyright © 2018 Jovi. All rights reserved.
//

#import "AppDelegate.h"
#import <ShadowstarKit/ShadowstarKit.h>
#import "MacSystemInformation.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate{
    IBOutlet NSTextField *lbTip;
    NSMutableDictionary *_dictDriveInfo;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [[lbTip cell] setLineBreakMode:NSLineBreakByWordWrapping];
    [[lbTip cell] setScrollable:NO];
    _dictDriveInfo = [[NSMutableDictionary alloc] init];
    [[SSDiskManager sharedManager] setDiskChangedBlock:^(DADiskRef disk, SSDiskNotification_Type type) {
        if(eSSDiskNotification_DiskAppeared != type){
            return;
        }
        NSString *bsdName = [SSDiskManager bsdnameForDiskRef:disk];
        if (nil == bsdName) {
            return;
        }
        NSMutableDictionary *dictData = [[NSMutableDictionary alloc]initWithDictionary:CFBridgingRelease(DADiskCopyDescription(disk))];
        NSString *strMediaUUID = [NSString stringWithFormat:@"%@",[dictData objectForKey:(NSString *)kDADiskDescriptionMediaUUIDKey]];
        NSString *strVolumeUUID = [NSString stringWithFormat:@"%@",[dictData objectForKey:(NSString *)kDADiskDescriptionVolumeUUIDKey]];
        NSString *strVolumePath = [NSString stringWithFormat:@"%@",[dictData objectForKey:(NSString *)kDADiskDescriptionVolumePathKey]];
        
        [dictData setObject:strMediaUUID forKey:(NSString *)kDADiskDescriptionMediaUUIDKey];
        [dictData setObject:strVolumeUUID forKey:(NSString *)kDADiskDescriptionVolumeUUIDKey];
        [dictData setObject:strVolumePath forKey:(NSString *)kDADiskDescriptionVolumePathKey];
        [self->_dictDriveInfo setValue:[dictData copy] forKey:bsdName];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

-(IBAction)takeSystemSnapshots_click:(id)sender{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[MacSystemInformation serialNumber] forKey:@"serialNumber"];
    [dict setValue:[MacSystemInformation deviceType] forKey:@"deviceType"];
    [dict setValue:[MacSystemInformation systemLanguage] forKey:@"systemLanguage"];
    [dict setValue:[MacSystemInformation systemVersion] forKey:@"systemVersion"];
    [dict setValue:[MacSystemInformation physicalMemory] forKey:@"physicalMemory"];
    [dict setValue:[MacSystemInformation cpuInfo] forKey:@"cpuInfo"];
    [dict setValue:[MacSystemInformation graphicsInfo] forKey:@"graphicsInfo"];
    [dict setValue:[MacSystemInformation systemUptime] forKey:@"systemUptime"];
    [dict setValue:_dictDriveInfo forKey:@"drives"];
    
    [lbTip setStringValue:@""];
    NSString *snapshotName = [NSString stringWithFormat:@"SystemSnapshot_%ld.plist", time(NULL)];
    
    NSSavePanel* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:snapshotName];
    [panel setMessage:NSLocalizedString(@"Choose a path to save System Snapshots", nil)];
    [panel setPrompt:NSLocalizedString(@"OK", nil)];
    
    NSWindow *bWindow = [self window];
    [panel beginSheetModalForWindow:bWindow completionHandler:^(NSInteger result){
        [panel orderOut:self];
        if (NSModalResponseOK != result) {
            return;
        }
        NSString *savePath = [[panel URL] path];
        [dict writeToFile:savePath atomically:YES];
        [self->lbTip setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The system snapshot has been saved at:  %@", nil),savePath]];
    }];
}

@end
