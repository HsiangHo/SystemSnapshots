//
//  MacSystemInformation.h
//  System Snapshots
//
//  Created by Jovi on 12/28/18.
//  Copyright © 2018 Jovi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MacSystemInformation : NSObject

// return value like 'C02WK53HHV2M'
+(NSString *)serialNumber;

// return value like 'MacbookPro14,2'
+(NSString *)deviceType;

// return value like 'en'
+(NSString *)systemLanguage;

// return value like '10.14.1'
+(NSString *)systemVersion;

// return value like '8G'
+(NSString *)physicalMemory;

// return value like 'Intel(R) Core(TM) i5-7267U CPU @ 3.10GHz'
+(NSString *)cpuInfo;

// return value like 'Intel Iris Plus Graphics 650'
+(NSString *)graphicsInfo;

+(BOOL)sipStatusOn;

+(NSString *)systemUptime;

@end

NS_ASSUME_NONNULL_END
