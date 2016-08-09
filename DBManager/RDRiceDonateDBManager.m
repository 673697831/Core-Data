//
//  RDRiceDonateDBManager.m
//  CDTest
//
//  Created by xia xl on 15/04/06.
//  Copyright (c) 2015年 xia xl. All rights reserved.
//

#import "RDRiceDonateDBManager.h"
#import "DBErrorDef.h"
#import "RiceDonate.h"

#import "RDPageStatsInfo.h"
#import "DBErrorDef.h"

#import "RDPageStatsCount.h"
#import "NSString+RDUUID.h"

//static RDRiceDonateDBManager *gInstance = nil;


@implementation RDRiceDonateDBManager


#pragma mark -初始化


- (DBDAO *)sportRecordDAO
{
    if(_riceDonateDAO == nil) {
        _riceDonateDAO = [[DBDAO alloc] init];
        [_riceDonateDAO associateManagedObjectModel:[NSString stringWithFormat:@"%@", kRDManagedObjectModelName]
                                         sqliteName:[NSString stringWithFormat:@"%@", kRDSqliteName]];
    }
    return _riceDonateDAO;
}

/*!
 @method
 @abstract RDRiceDonateDBManager单例
 @discussion
 @return
 */
+ (RDRiceDonateDBManager *)shareInstance
{
    static RDRiceDonateDBManager* manager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [RDRiceDonateDBManager new];
        [manager sportRecordDAO];
        [manager dbQueue];
    });
    
    return manager;
}

- (void)dbQueue
{
    if (!_dbQueue) {
        _dbQueue = dispatch_queue_create("com.dbqueue", DISPATCH_QUEUE_CONCURRENT);
    }
}

- (dispatch_queue_t)getDBQueue
{
    return _dbQueue;
}

#pragma mark -创建NSManagedObject对象
/*!
 @method
 @abstract 创建NSManagedObject对象
 @discussion
 @param modelName 类名称
 @return NSManagedObject对象
 */
- (NSManagedObject *)createModelWithName:(NSString *)modelName
{
    return [_riceDonateDAO createModelWithName:modelName];
}

/*!
 @method
 @abstract 插入一条数据 不区分type 内部处理
 @discussion
 @param entity 实体对象
 @param succcall
 @param failcall
 */
- (void)insertOneItem:(NSObject *)entity succBlock:(void(^)(void))succcall failedBlock:(void(^)(NSError *error))failcall
{
    dispatch_barrier_async(_dbQueue, ^{
        @autoreleasepool {
            BOOL bSuccess = [self insertOneItem:entity];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (!bSuccess) {
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                    [userInfo setObject:@"insert error" forKey:NSLocalizedDescriptionKey];
                    NSError *aError = [NSError errorWithDomain:RDDBErrorDomain code:kRDDBErrorTypeInsert userInfo:userInfo];
                    if (failcall) {
                        failcall(aError);
                    }
                }
                else {
                    if (succcall) {
                        succcall();
                    }
                }
            });
        }
    });
}

/*!
 @method
 @abstract 插入一个点数据
 @discussion
 @param entity 源数据
 */
- (BOOL)insertOneItem:(id)entity
{
//    RDPageStatsInfo *pageStatsInfo = (RDPageStatsInfo *)[self createModelWithName:[NSString stringWithFormat:@"%@", kRDTablePageStatsInfo]];
//    if (!pageStatsInfo) {
//        return NO;
//    }
//    
    //[DBParser assembleSportRecord:oneRecord entity:entity];
    
    [_riceDonateDAO insertToTable:[NSString stringWithFormat:@"%@", kTablePageStatsInfo]
                   withDictionary:entity];
    return [_riceDonateDAO commitWithContext];
}

/*!
 @method
 @abstract 删除单条数据
 @discussion
 @param guid
 @param succcall
 @param failcall
 */
- (void)deleteOneItem:(NSString *)guid succBlock:(void(^)(void))succcall failedBlock:(void(^)(NSError *error))failcall
{
    dispatch_barrier_async(_dbQueue, ^{
        @autoreleasepool {
            NSString *condition = [NSString stringWithFormat:@"%@=\"%@\"", RECORD_EVENT_GUID, guid];
            __unused NSArray *fetchResult = [_riceDonateDAO fetchFromTable:TABLE_RICEDONATE seqWithKey:RECORD_EVENT_GUID ascending:NO condition:condition limit:0];
//            for (int i = 0; i < fetchResult.count; i++) {
//                SportRecord *record = (SportRecord *)[fetchResult objectAtIndex:i];
//                [_riceDonateDAO deleteModel:record];
//            }
            
            BOOL bSuccess = [_riceDonateDAO commitWithContext];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (!bSuccess) {
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                    [userInfo setObject:@"delete error" forKey:NSLocalizedDescriptionKey];
                    NSError *aError = [NSError errorWithDomain:RDDBErrorDomain code:kRDDBErrorTypeDelete userInfo:userInfo];
                    failcall(aError);
                }
                else {
                    succcall();
                }
            });
        }
    });
    
}

/*!
 @method
 @abstract 查询单条数据
 @discussion
 @param guid
 @param succcall
 @param failcall
 */
-(BOOL)updateOneItem:(id)entity withContent:(NSDictionary *)dic{

//    NSString *condition = [NSString stringWithFormat:@"day=\"%@\"",[self getDateStringFromDate:[entity cTime]]];
//    return [_riceDonateDAO updateToTable:TABLE_RICEDONATE withDictionary:dic condition:condition seqKey:@"cTime"];
    return YES;
}

/*!
 @method
 @abstract 查询单条数据
 @discussion
 @param guid
 @param succcall
 @param failcall
 */
- (void)fetchItemsWithCTime:(int)ctime succBlock:(void (^)(id))succcall failedBlock:(void (^)(NSError *))failcall
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            NSString *tableName = TABLE_RICEDONATE;
            NSString *condition = [NSString stringWithFormat:@"(1=1)"];
            NSArray *fetchResult = [_riceDonateDAO fetchFromTable:tableName seqWithKey:RECORD_EVENT_CTIME ascending:YES condition:condition limit:0];
            
            [_riceDonateDAO cleanCache];
            dispatch_sync(dispatch_get_main_queue(), ^{
                succcall(fetchResult);
            });
        }
        
    });
    
}

- (void)fetchItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate succBlock:(void (^)(NSArray *))succcal failedBlock:(void(^)(NSError *))failcall
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            NSString *tableName = TABLE_RICEDONATE;
            NSString *fromDateStr = [self getDateStringFromDate:fromDate];
            NSString *toDateStr = [self getDateStringFromDate:toDate];
            NSDate *from = [self getDateFromDateString:fromDateStr];
            NSDate *to = [self getDateFromDateString:toDateStr];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cTime >= %@ AND cTime <= %@",from,to];
            __unused NSArray *fetchResult = [_riceDonateDAO fetchFromTable:tableName seqWithKey:RECORD_EVENT_CTIME ascending:NO predicate:predicate limit:-1];
            
            NSMutableArray *uiDataArr = [[NSMutableArray alloc] init];
//            for (int i=0; i<[fetchResult count]; i++) {
//                [uiDataArr addObject:[DBParser assembleSportRecordUIData:[fetchResult objectAtIndex:i]]];
//            }
            [_riceDonateDAO cleanCache];
            dispatch_async(dispatch_get_main_queue(), ^{
                succcal(uiDataArr);
            });
        }
    });
}

- (void)fetchAllStepsCountSuccBlock:(void (^)(NSNumber *))succcal failedBlock:(void(^)(NSError *))failcall
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            NSString *tableName = TABLE_RICEDONATE;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"1=1"];
            __unused NSArray *fetchResult = [_riceDonateDAO fetchFromTable:tableName seqWithKey:RECORD_EVENT_CTIME ascending:NO predicate:predicate limit:-1];
            int allStepsCount = 0;
//            for (int i=0; i<[fetchResult count]; i++) {
//                allStepsCount+=[[[fetchResult objectAtIndex:i] steps] intValue];
//            }
            NSNumber *allCountNum = [NSNumber numberWithInt:allStepsCount];
            [_riceDonateDAO cleanCache];
            dispatch_async(dispatch_get_main_queue(), ^{
                succcal(allCountNum);
            });
        }
    });
}


#pragma mark - tools
-(NSString *)getDateStringFromDate:(NSDate *)date
{
    NSString *dateString = @"";
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];//@"yyyy.MM.dd EEEE",@"HH:mm"
    //用[NSDate date]可以获取系统当前时间
    dateString = [dateFormatter stringFromDate:date];
    //输出格式为：2010-10-27 10:22:13
    NSLog(@"%@",dateString);
    
    return dateString;
}

-(NSDate *)getDateFromDateString:(NSString *)dateString
{
    NSDate *date= nil;
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];//@"yyyy.MM.dd EEEE",@"HH:mm"
    //用[NSDate date]可以获取系统当前时间
    date = [dateFormatter dateFromString:dateString];
    //输出格式为：2010-10-27 10:22:13
    NSLog(@"%@",date);
    
    return date;
}

- (NSString*)getGuid
{
    CFUUIDRef puuid = CFUUIDCreate( nil );
    CFStringRef uuidString = CFUUIDCreateString( nil, puuid );
    NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}

- (void)fetchPageStatsCountWithSuccessBlock:(void (^)(id))successBlock
                               failureBlock:(void (^)(NSError *))failureBlock;
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            
            NSString *tableName = [NSString stringWithFormat:@"%@", kTablePageStatsCount];
            NSString *condition = [NSString stringWithFormat:@"(1=1)"];
            NSArray *fetchResult = [_riceDonateDAO fetchFromTable:tableName
                                                       seqWithKey:@"uuid"
                                                        ascending:YES
                                                        condition:condition
                                                            limit:0];
            RDDBErrorType type;
            BOOL result;
            NSDictionary *returnDictionary = nil;
            if (fetchResult.count >0) {
                type = kRDDBErrorTypeUpdate;
                RDPageStatsCount *obj = fetchResult[0];
                obj.uploadCount = @([obj.uploadCount integerValue] + 1);
                result = [_riceDonateDAO commitWithContext];
                returnDictionary = @{
                                     @"uploadCount":obj.uploadCount,
                                     @"uuid":obj.uuid,
                                     };
            }else
            {
                type = kRDDBErrorTypeInsert;
                returnDictionary = @{
                    @"uploadCount":@0,
                    @"uuid":[NSString rd_randomId],
                };
                result = [_riceDonateDAO updateToTable:[NSString stringWithFormat:@"%@", kTablePageStatsCount]
                                        withDictionary:returnDictionary
                                             condition:condition
                                                seqKey:@"uuid"];
            }
            
            [_riceDonateDAO cleanCache];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (result) {
                    if (successBlock) {
                        successBlock(returnDictionary);
                    }
                }else
                {
                    if (failureBlock) {
                        failureBlock([[NSError alloc] initWithDomain:RDDBErrorDomain
                                                                code:type
                                                            userInfo:nil]);
                    }
                }
            });
        }
        
    });
}

- (void)deletePageStatsInfoWithRecordTime:(NSTimeInterval)recordTime
                             successBlock:(void (^)())successBlock
                             failureBlock:(void (^)(NSError *))failureBlock;
{
    dispatch_barrier_async(_dbQueue, ^{
        @autoreleasepool {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordTime <= %f", recordTime];
            NSArray *fetchResult = [_riceDonateDAO fetchFromTable:[NSString stringWithFormat:@"%@", kTablePageStatsInfo]
                                                       seqWithKey:@"recordTime"
                                                        ascending:NO
                                                        predicate:predicate
                                                            limit:-1];
            for (int i = 0; i < fetchResult.count; i++) {
                RDPageStatsInfo *record = (RDPageStatsInfo *)[fetchResult objectAtIndex:i];
                [_riceDonateDAO deleteModel:record];
            }
            [_riceDonateDAO commitWithContext];
            [_riceDonateDAO cleanCache];
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                if (result) {
//                    if (successBlock) {
//                        successBlock();
//                    }
//                }else
//                {
//                    if (failureBlock) {
//                        failureBlock([[NSError alloc] initWithDomain:RDDBErrorDomain
//                                                                code:kRDDBErrorTypeDelete
//                                                            userInfo:nil]);
//                    }
//                }
//            });

        }
    });
}

- (void)insertPageStatsInfo:(NSDictionary *)dictionary
               successBlock:(void (^)())successBlock
               failureBlock:(void (^)(NSError *))failureBlock;
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            [_riceDonateDAO insertToTable:[NSString stringWithFormat:@"%@", kTablePageStatsInfo]
                           withDictionary:dictionary];
            BOOL result = [_riceDonateDAO commitWithContext];
            [_riceDonateDAO cleanCache];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (result) {
                    if (successBlock) {
                        successBlock();
                    }
                }else
                {
                    if (failureBlock) {
                        failureBlock([[NSError alloc] initWithDomain:RDDBErrorDomain
                                                                code:kRDDBErrorTypeInsert
                                                            userInfo:nil]);
                    }
                }
            });
        }
        
    });
}

- (void)fetchAllPageStatsInfoWithSuccessBlock:(void (^)(NSArray *))successBlock
                                 failureBlock:(void (^)(NSError *))failureBlock
{
    dispatch_async(_dbQueue, ^{
        @autoreleasepool {
            NSString *tableName = [NSString stringWithFormat:@"%@", kTablePageStatsInfo];
            NSString *condition = [NSString stringWithFormat:@"(1=1)"];
            NSArray *fetchResult = [_riceDonateDAO fetchFromTable:tableName seqWithKey:@"recordTime" ascending:YES condition:condition limit:0];
            NSMutableArray *mutableArray = [NSMutableArray new];
            for (RDPageStatsInfo *statsInfo in fetchResult) {
                NSInteger millisecond = (long)([statsInfo.stayTime floatValue] * 1000);
                [mutableArray addObject:@{@"page_name":statsInfo.pageName, @"time":@(millisecond)}];
            }
            
            [_riceDonateDAO cleanCache];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (fetchResult) {
                    if (successBlock) {
                        successBlock(mutableArray);
                    }
                }else
                {
                    if (failureBlock) {
                        failureBlock([[NSError alloc] initWithDomain:RDDBErrorDomain
                                                                code:kRDDBErrorTypeSearch
                                                            userInfo:nil]);
                    }
                }
            });
        }
        
    });
}

@end
