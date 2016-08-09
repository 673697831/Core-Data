//
//  RDRiceDonateDBManager.h
//  CDTest
//
//  Created by xia xl on 15/04/06.
//  Copyright (c) 2015年 xia xl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBDAO.h"

#define TABLE_RICEDONATE                  @"RiceDonate"

#define RECORD_EVENT_GUID                   @"guid"
#define RECORD_EVENT_CTIME                  @"cTime"

static const NSString* kRDSqliteName = @"RiceDonateData";
static const NSString* kRDManagedObjectModelName = @"RiceDonateData";

static const NSString* kTablePageStatsCount = @"RDPageStatsCount";
static const NSString* kTablePageStatsInfo = @"RDPageStatsInfo";

@class RDPageStatsCount;
@class RDPageStatsInfo;

@interface RDRiceDonateDBManager : NSObject
{
    DBDAO *_riceDonateDAO;
    dispatch_queue_t _dbQueue;
}

/*!
 @method
 @abstract DB单例
 @discussion
 @return
 */
+ (RDRiceDonateDBManager *)shareInstance;

- (dispatch_queue_t)getDBQueue;

/*!
 @method
 @abstract 创建NSManagedObject对象
 @discussion
 @param modelName 类名称
 @return NSManagedObject对象
 */
- (NSManagedObject *)createModelWithName:(NSString *)modelName;

#pragma mark -插入一条数据
/*!
 @method
 @abstract 插入一条数据 不区分type 内部处理
 @discussion
 @param entity 实体对象
 @param succcall
 @param failcall
 */
- (void)insertOneItem:(NSObject *)entity  succBlock:(void(^)(void))succcall failedBlock:(void(^)(NSError *error))failcall;

/*!
 @method
 @abstract 更新单条数据
 @discussion
 @param entity UI展示数据结构
 @return BOOL 返回是否更新成功
 */
-(BOOL)updateOneItem:(id)entity withContent:(NSDictionary *)dic;


/*!
 @method
 @abstract  获取数据从开始日期 到 结束日期之前的数据
 @discussion
 @param fromDate  开始日期
 @param toDate    结束日期
 @param succcall
 @param failcall
 */
- (void)fetchItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate succBlock:(void (^)(NSArray *))succcal failedBlock:(void(^)(NSError *))failcall;

/*!
 @method
 @abstract  获取所有步数
 @discussion
 @param succcall
 @param failcall
 */
- (void)fetchAllStepsCountSuccBlock:(void (^)(NSNumber *))succcal failedBlock:(void(^)(NSError *))failcall;

- (NSString*)getGuid;
-(NSString *)getDateStringFromDate:(NSDate *)date;
- (NSDate *)getDateFromDateString:(NSString *)dateString;

- (void)fetchPageStatsCountWithSuccessBlock:(void (^)(id))successBlock
                               failureBlock:(void (^)(NSError *))failureBlock;
- (void)fetchAllPageStatsInfoWithSuccessBlock:(void (^)(NSArray *))successBlock
                                 failureBlock:(void (^)(NSError *))failureBlock;

- (void)deletePageStatsInfoWithRecordTime:(NSTimeInterval)recordTime
                             successBlock:(void (^)())successBlock
                             failureBlock:(void (^)(NSError *))failureBlock;
- (void)insertPageStatsInfo:(NSDictionary *)dictionary
               successBlock:(void (^)())successBlock
               failureBlock:(void (^)(NSError *))failureBlock;

@end
