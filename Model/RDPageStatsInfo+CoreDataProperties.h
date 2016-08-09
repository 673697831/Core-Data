//
//  RDPageStatsInfo+CoreDataProperties.h
//  RiceDonate
//
//  Created by ozr on 16/5/6.
//  Copyright © 2016年 ricedonate. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "RDPageStatsInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDPageStatsInfo (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *pageName;
@property (nullable, nonatomic, retain) NSNumber *stayTime;
@property (nullable, nonatomic, retain) NSNumber *recordTime;

@end

NS_ASSUME_NONNULL_END
