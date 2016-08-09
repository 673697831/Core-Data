//
//  DBErrorDef.h
//  CDTest
//
//  Created by xia xl on 15/04/06.
//  Copyright (c) 2015年 xia xl. All rights reserved.
//

#ifndef CDTest_DBErrorDef_h
#define CDTest_DBErrorDef_h

#define RDDBErrorDomain             @"com.RiceDonate.db"

typedef NS_ENUM(NSUInteger, RDDBErrorType) {
    kRDDBErrorTypeInsert = 1000,
    kRDDBErrorTypeDelete = 1010,
    kRDDBErrorTypeUpdate = 1020,
    kRDDBErrorTypeSearch = 1030,
};

#endif
