//
//  RDPageStatsCount+CoreDataProperties.h
//  RiceDonate
//
//  Created by ozr on 16/4/29.
//  Copyright © 2016年 ricedonate. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "RDPageStatsCount.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDPageStatsCount (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *uploadCount;
@property (nullable, nonatomic, retain) NSString *uuid;

@end

NS_ASSUME_NONNULL_END
