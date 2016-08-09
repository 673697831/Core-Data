//
//  RiceDonate.h
//  RiceDonate
//
//  Created by xia xl on 15/4/6.
//  Copyright (c) 2015年 tietie tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RiceDonate : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * gameInfo;
@property (nonatomic, retain) NSString * riceCount;

@end
