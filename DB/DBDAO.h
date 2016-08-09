//
//  DBDAO.h
//  CDTest
//
//  Created by xia xl on 15/04/06.
//  Copyright (c) 2015年 xia xl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DBDAO : NSObject

/*!
 @property
 @abstract 实体对象集合
 */
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
/*!
 @property
 @abstract 持久存储对象
 */
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
/*!
 @property
 @abstract 数据库lock
 */
@property (nonatomic, retain, readonly) NSLock *dbLock;
/*!
 @property
 @abstract 上下文
 */
@property (nonatomic, retain, readonly) NSMutableDictionary *contextPool;

/*!
 @method
 @abstract 上线文关联数据库
 @discussion
 @param managedObjectModelName 数据库名称    
 */
- (void)associateManagedObjectModel:(NSString *)managedObjectModelName sqliteName:(NSString *)sqliteName;

/*!
 @method
 @abstract 新增数据
 @discussion
 @param table 表名称
 @param dataDic 新增数据 NSDictionary类型
 */
- (void)insertToTable:(NSString*)table withDictionary:(NSDictionary *)dataDic;

/*!
 @method
 @abstract 更新数据(暂时只支持更新一条数据)
 @discussion
 @param table 表名称
 @param dataDic 更新数据
 @param condition 查询条件
 @param seqKey  表字段
 @return
 */
- (BOOL)updateToTable:(NSString*)table withDictionary:(NSDictionary *)dataDic condition:(NSString*)condition seqKey:(NSString*)seqKey;

/*!
 @method
 @abstract 查询数据
 @discussion
 @param tableName 表名称
 @param seqKey 表字段 (配合isAscending字段使用)
 @param isAscending 是否升序 (配合seqKey字段使用)
 @param condition   查询条件
 @param limit   数量限制
 @return
 */
- (NSArray *)fetchFromTable:(NSString*)tableName
                                     seqWithKey:(NSString*)seqKey
                                      ascending:(BOOL)isAscending
                                      condition:(NSString*)condition
                                          limit:(int)limit;

- (NSArray *)fetchFromTable:(NSString*)tableName
                 seqWithKey:(NSString*)seqKey
                  ascending:(BOOL)isAscending
                  predicate:(NSPredicate*)predicate
                      limit:(int)limit;



/*!
 @method
 @abstract 按照查询条件得到的数据的数量
 @discussion
 @param tableName 表名称
 @param condition 查询条件
 */
- (NSInteger)getCountFromTable:(NSString *)tableName condition:(NSString *)condition;

/*!
 @method
 @abstract 返回去重之后的某个key
 @discussion
 @param tableName 表名称
 @param fetchKey fetch key
 @param condition 筛选条件
 @return
 */
- (NSArray *)fetchKeysFromTable:(NSString *)tableName fetchKey:(NSString *)fetchKey condition:(NSString *)condition;

/*!
 @method
 @abstract 按照筛选条件删除数据
 @discussion
 @param table 表名称
 @param condition 查询条件
 @param seqKey 表字段
 */
- (void)deleteFromTable:(NSString*)table condition:(NSString*)condition seqKey:(NSString*)seqKey;

/*!
 @method
 @abstract 删除单个对象
 @discussion
 @param model 将要删除的对象
 */
- (void)deleteModel:(NSManagedObject *)model;

/*!
 @method
 @abstract commit unsaved changes to registered objects to the receiver’s parent store
 @discussion
 */
- (BOOL)commitWithContext;

/*!
 @method
 @abstract 创建NSManagedObject对象
 @discussion
 @param modelName 类名称
 @return NSManagedObject对象
 */
- (NSManagedObject *)createModelWithName:(NSString *)modelName;

- (void)cleanCache;

@end
