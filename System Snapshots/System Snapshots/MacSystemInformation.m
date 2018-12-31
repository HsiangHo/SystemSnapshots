//
//  MacSystemInformation.m
//  System Snapshots
//
//  Created by Jovi on 12/28/18.
//  Copyright © 2018 Jovi. All rights reserved.
//

#import "MacSystemInformation.h"

@implementation MacSystemInformation

+(NSString *)serialNumber{
    NSString *strRlst = @"UNAVAILABLE";
    char serialNumber[256] = {0};
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    if (platformExpert){
        CFTypeRef serialNumberCF =  IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault,0);
        IOObjectRelease(platformExpert);
        if(NULL != serialNumberCF){
            if(CFGetTypeID(serialNumberCF)==CFDataGetTypeID()){
                CFRange cfrange = CFRangeMake(0,CFDataGetLength((CFDataRef)serialNumberCF));
                CFDataGetBytes((CFDataRef)serialNumberCF,cfrange,(UInt8*)serialNumber);
            }else if(CFGetTypeID(serialNumberCF)==CFStringGetTypeID()){
                CFStringGetCString((CFStringRef)serialNumberCF, serialNumber,255, kCFStringEncodingUTF8);
            }
            CFRelease(serialNumberCF);
            strRlst = [NSString stringWithUTF8String:serialNumber];
        }
    }
    return strRlst;
}

+(NSString *)deviceType{
    NSString *strRslt = @"UNAVAILABLE";
    size_t size = 0;
    sysctlbyname("hw.model", nil, &size, nil, 0);
    char *pMachine = (char *)malloc(size + 1);
    if (size > 0 && NULL != pMachine) {
        sysctlbyname("hw.model", pMachine, &size, nil, 0);
        strRslt = [NSString stringWithUTF8String:pMachine];
        free(pMachine);
    }
    return strRslt;
}

+(NSString *)cpuInfo{
    NSString *strRslt = @"UNAVAILABLE";
    size_t size = 0;
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0);
    char *pMachine = (char *)malloc(size + 1);
    if (size > 0 && NULL != pMachine) {
        sysctlbyname("machdep.cpu.brand_string", pMachine, &size, nil, 0);
        strRslt = [NSString stringWithUTF8String:pMachine];
        free(pMachine);
    }
    return strRslt;
}

+(NSString *)graphicsInfo{
    NSString *graphicsModel = @"UNAVAILABLE";
    CFMutableDictionaryRef matchDict = IOServiceMatching("IOPCIDevice");
    io_iterator_t iterator;
    if (kIOReturnSuccess == IOServiceGetMatchingServices(kIOMasterPortDefault,matchDict, &iterator)){
        io_registry_entry_t regEntry;
        while ((regEntry = IOIteratorNext(iterator))) {
            // Put this services object into a dictionary object.
            CFMutableDictionaryRef serviceDictionary;
            if (kIOReturnSuccess != IORegistryEntryCreateCFProperties(regEntry, &serviceDictionary, kCFAllocatorDefault, kNilOptions)){
                IOObjectRelease(regEntry);
                continue;
            }
            const void *GPUModel = CFDictionaryGetValue(serviceDictionary, @"model");
            if (nil != GPUModel) {
                if (CFGetTypeID(GPUModel) == CFDataGetTypeID()) {
                    // Create a string from the CFDataRef.
                    graphicsModel = [[NSString alloc] initWithData: (__bridge NSData *)GPUModel encoding:NSASCIIStringEncoding];
                }
            }
            CFRelease(serviceDictionary);
            IOObjectRelease(regEntry);
        }
        IOObjectRelease(iterator);
    }
    return graphicsModel;
}

+(NSString *)systemLanguage{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

+(NSString *)systemVersion{
    NSString *strRlst = @"UNAVAILABLE";
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
        NSOperatingSystemVersion osSystemVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
        strRlst = [NSString stringWithFormat:@"%li.%li.%li",(long)osSystemVersion.majorVersion,(long)osSystemVersion.minorVersion,(long)osSystemVersion.patchVersion];
    }else {
        SInt32 majorVersion, minorVersion, patchVersion;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        Gestalt(gestaltSystemVersionMajor, &majorVersion);
        Gestalt(gestaltSystemVersionMinor, &minorVersion);
        Gestalt(gestaltSystemVersionBugFix, &patchVersion);
#pragma clang diagnostic pop
        
        strRlst = [NSString stringWithFormat:@"%li.%li.%li",(long)majorVersion,(long)minorVersion,(long)patchVersion];
    }
    return strRlst;
}

+(NSString *)physicalMemory{
    return [NSString stringWithFormat:@"%llu GB",[[NSProcessInfo processInfo] physicalMemory] / (1024 * 1024 * 1024)];
}

+(BOOL)sipStatusOn{
    BOOL bStatus = YES;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", @"csrutil status"]];
    
    NSPipe *responsePipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:responsePipe];
    [task setStandardError:errorPipe];
    [task launch];
    [task waitUntilExit];
    
    NSString *response = [[NSString alloc] initWithData:[responsePipe.fileHandleForReading readDataToEndOfFile]
                                               encoding:NSUTF8StringEncoding];
    if (NSNotFound != [response rangeOfString:@"disable"].location) {
        bStatus = NO;
    }
    
    return bStatus;
}

+(NSString *)startupVolumeType{
    NSString *strRslt = @"UNKNOWN";
    DADiskRef disk;
    DASessionRef session = DASessionCreate(NULL);
    char *mountPoint = "/";
    if(NULL != session){
        CFURLRef url = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)mountPoint, strlen(mountPoint), TRUE);
        disk = DADiskCreateFromVolumePath(NULL, session, url);
        if (NULL != disk) {
            NSDictionary *dictData = CFBridgingRelease(DADiskCopyDescription(disk));
            strRslt = [dictData valueForKey:(NSString *)kDADiskDescriptionVolumeTypeKey];
            CFRelease(disk);
        }
        if (NULL != url) {
            CFRelease(url);
        }
        CFRelease(session);
    }
    return strRslt;
}

+(NSString *)systemUptime{
    return [NSString stringWithFormat:@"%f",[[NSProcessInfo processInfo] systemUptime]];
}

@end
