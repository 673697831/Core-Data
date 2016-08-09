//
//  DBDAO.m
//  CDTest
//
//  Created by xia xl on 15/04/06.
//  Copyright (c) 2015年 xia xl. All rights reserved.
//

#import "DBDAO.h"


@implementation DBDAO

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize dbLock = _dbLock;
@synthesize contextPool = _contextPool;

#pragma mark 初始化

- (id)init
{
    self = [super init];
    if (self) {
        [self dbLock];
        [self contextPool];
    }
    return self;
}

- (NSLock *)dbLock
{
    if(_dbLock == nil) {
        _dbLock = [[NSLock alloc] init];
    }
    return _dbLock;
}

- (NSMutableDictionary *)contextPool
{
    if(_contextPool == nil) {
        _contextPool = [[NSMutableDictionary alloc] init];
    }
    return _contextPool;
}

//允许多个数据库 即本地可以同时存在多个.xcdatamodeld文件
#pragma mark -上线文关联数据库
/*!
 @method
 @abstract 上线文关关联数据库
 @discussion
 @param managedObjectModelName 数据库名称
 */
- (void)associateManagedObjectModel:(NSString *)managedObjectModelName sqliteName:(NSString *)sqliteName
{
    [_dbLock lock];
    _managedObjectModel = nil;
    _persistentStoreCoordinator = nil;
    [self managedObjectModel:managedObjectModelName];
    [self persistentStoreCoordinator:sqliteName];
    [_dbLock unlock];
}

/*!
 @method
 @abstract Returns the path to the application's documents directory.
 @discussion
 @return
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/*!
 @method
 @abstract 上下文关联PersistentStoreCoordinator
 @discussion
 */
- (void)contextAssociatePersistentStoreCoordinator
{
    [_dbLock lock];
    [self bindingContextPool];
    for(NSString *key in [_contextPool allKeys])
    {
        NSManagedObjectContext *managedObjectContext = [_contextPool objectForKey:key];
        if(managedObjectContext.persistentStoreCoordinator)
            continue;
        if (!_persistentStoreCoordinator) {
            continue;
        }
        [managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    }
    [_dbLock unlock];
}

/*!
 @method
 @abstract 子线程绑定context pool
 @discussion
 */
- (void)bindingContextPool
{
    NSString *key = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    if(key && ![key isEqualToString:@""])
    {
        NSManagedObjectContext *managedObjectContext = [_contextPool objectForKey:key];
        if(managedObjectContext == nil)
        {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_contextPool setObject:managedObjectContext forKey:key];
        }
    }
}


/*!
 @method
 @abstract Returns the managed object model for the application.
            If the model doesn't already exist, it is created from the application's model.
 @discussion
 @return
 */
- (NSManagedObjectModel *)managedObjectModel:(NSString *)managedObjectModelName
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"%@", managedObjectModelName] withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return self.managedObjectModel;
}

/*!
 @method
 @abstract Returns the managed object model for the application.
        If the model doesn't already exist, it is created from the application's model.
 @discussion
 @param sqliteName
 @return
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator:(NSString *)sqliteName
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", sqliteName]];
    
    NSError *error = nil;
    
    NSManagedObjectModel *managedObject = [self managedObjectModel];
    if (managedObject) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    }
    else {
        _persistentStoreCoordinator = nil;
        return nil;
    }
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],
                             NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES],
                             NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        NSLog(@"persistentStoreCoordinator error %@, %@", error, [error userInfo]);
        _persistentStoreCoordinator = nil;
        return nil;
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark -数据库操作

- (NSManagedObjectContext *)getManagedObjectContext
{
    [_dbLock lock];
    NSManagedObjectContext *managedObjectContext = nil;
    NSString *key = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    if(key && ![key isEqualToString:@""])
    {
        managedObjectContext = [_contextPool objectForKey:key];
    }
    if(managedObjectContext == nil)
    {
        NSLog(@"unknown thread access");
    }
    [_dbLock unlock];
    return managedObjectContext;
}

/*!
 @method
 @abstract 创建NSManagedObject对象
 @discussion
 @param modelName 类名称
 @return NSManagedObject对象
 */
- (NSManagedObject *)createModelWithName:(NSString *)modelName
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
    if (!managedObjectContext || !_persistentStoreCoordinator) {
        return nil;
    }
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:modelName
                                                                      inManagedObjectContext:managedObjectContext];
    return newManagedObject;
}

/*!
 @method
 @abstract 新增数据
 @discussion
 @param table 表名称
 @param dataDic 新增数据
 */
- (void)insertToTable:(NSString*)table withDictionary:(NSDictionary *)dataDic
{
    @try {
        [self contextAssociatePersistentStoreCoordinator];
        NSManagedObjectContext *managedObjectContext = [self getManagedObjectContext];
        if (!managedObjectContext || !_persistentStoreCoordinator) {
            return;
        }
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:table
                                                                          inManagedObjectContext:managedObjectContext];
        // If appropriate, configure the new managed object.
        
        [newManagedObject setValuesForKeysWithDictionary:dataDic];
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
    
}

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
- (BOOL)updateToTable:(NSString*)table withDictionary:(NSDictionary *)dataDic condition:(NSString*)condition seqKey:(NSString*)seqKey
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return NO;
    }
    NSArray *fetchResult = [self fetchFromTable:table
                                     seqWithKey:seqKey
                                      ascending:NO
                                      condition:condition
                                          limit:0];
    if (fetchResult.count > 0) {
        NSManagedObject *mObject = [fetchResult objectAtIndex:0];
        if (mObject) {
            [mObject setValuesForKeysWithDictionary:dataDic];
        }
        else {
            return NO;
        }
    }
    else {
        NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:table inManagedObjectContext:context];
        [newManagedObject setValuesForKeysWithDictionary:dataDic];
    }
    return [self commitWithContext];
}

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
                                          limit:(int)limit
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return nil;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:tableName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:limit];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:seqKey ascending:isAscending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    //数据过滤条件
    if (condition && ![@""isEqualToString:condition]) {
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:condition]];
    }
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"performFetch error %@, %@", error, [error userInfo]);
    }
    
    return result;
}

- (NSArray *)fetchFromTable:(NSString*)tableName
                 seqWithKey:(NSString*)seqKey
                  ascending:(BOOL)isAscending
                  predicate:(NSPredicate*)predicate
                      limit:(int)limit
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return nil;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:tableName inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    if (limit>=0) {
        [fetchRequest setFetchLimit:limit];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:seqKey ascending:isAscending];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    //数据过滤条件
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    NSError *error = nil;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"performFetch error %@, %@", error, [error userInfo]);
    }
    
    return result;
}

/*!
 @method
 @abstract 按照查询条件得到的数据的数量
 @discussion
 @param tableName 表名称
 @param condition 查询条件
 */
- (NSInteger)getCountFromTable:(NSString *)tableName condition:(NSString *)condition
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return 0;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:tableName inManagedObjectContext:context]];
    [request setIncludesSubentities:NO];
    //数据过滤条件
    if (condition && ![@""isEqualToString:condition]) {
        [request setPredicate:[NSPredicate predicateWithFormat:condition]];
    }
    NSError *err;
    NSUInteger count = [context countForFetchRequest:request error:&err];
    return count;
}

/*!
 @method
 @abstract 返回去重之后的某个key
 @discussion
 @param tableName 表名称
 @param fetchKey fetch key
 @param condition 筛选条件
 @return
 */
- (NSArray *)fetchKeysFromTable:(NSString *)tableName fetchKey:(NSString *)fetchKey condition:(NSString *)condition
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return nil;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:tableName inManagedObjectContext:context];
    request.entity = entity;
    request.propertiesToFetch = [NSArray arrayWithObject:[[entity propertiesByName] objectForKey:fetchKey]];
    request.returnsDistinctResults = YES;
    request.resultType = NSDictionaryResultType;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:fetchKey ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    //数据过滤条件
    if (condition && ![@""isEqualToString:condition]) {
        [request setPredicate:[NSPredicate predicateWithFormat:condition]];
    }
    
    NSError *error = nil;
    NSArray *distincResults = [context executeFetchRequest:request error:&error];
    return distincResults;
}


/*!
 @method
 @abstract 按照筛选条件删除数据
 @discussion
 @param table 表名称
 @param condition 查询条件
 @param seqKey  表字段
 */
- (void)deleteFromTable:(NSString*)table condition:(NSString*)condition seqKey:(NSString*)seqKey
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return;
    }
    NSArray *fetchResult = [self fetchFromTable:table
                                                               seqWithKey:seqKey
                                                                ascending:NO
                                                                condition:condition
                                                                    limit:0];
    NSInteger objSize = [fetchResult count];
    if (objSize > 0) {
        for (int i = 0; i < objSize; i++) {
            [context deleteObject:[fetchResult objectAtIndex:i]];
        }
    }
}

/*!
 @method
 @abstract 删除单个对象
 @discussion
 @param model 将要删除的对象
 */
- (void)deleteModel:(NSManagedObject *)model
{
    [self contextAssociatePersistentStoreCoordinator];
    NSManagedObjectContext *context = [self getManagedObjectContext];
    if (!context || !_persistentStoreCoordinator) {
        return;
    }
    [context deleteObject:model];
}

/*!
 @method
 @abstract commit unsaved changes to registered objects to the receiver’s parent store
 @discussion
 */
- (BOOL)commitWithContext
{
    @try {
        NSManagedObjectContext *context = [self getManagedObjectContext];
        if (!context || !_persistentStoreCoordinator) {
            return NO;
        }
        // Save the context.
        NSError *error = nil;
        if ([context hasChanges] && ![context save:&error])
        {
            NSLog(@"commitWithContext error %@, %@", error, [error userInfo]);
            [self cleanCache];
            return NO;
        }
        [self cleanCache];
    }
    @catch (NSException *exception) {
    }
    @finally {
    }

    return YES;
}

//尼玛一定要清缓存 尼玛老是内存泄露不说 还合并失败 恶恶恶
- (void)cleanCache
{
    [_dbLock lock];
    NSString *key = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    if(key && ![key isEqualToString:@""]) {
        NSManagedObjectContext *managedObjectContext = [_contextPool objectForKey:key];
        [_contextPool removeObjectForKey:key];
        managedObjectContext = nil;
    }
    [_dbLock unlock];
}

@end
