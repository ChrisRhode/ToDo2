//
//  DBWrapper.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Utility.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBWrapper : NSObject
{
    NSString *fullPathToDBDFile;
    sqlite3 *db;
    Utility *ugbl;
    sqlite3_stmt *stmtForParamCommand;
    NSInteger insertParamCtr;
}

-(id) initForDbFile: (NSString *) fileNameWithoutPath;
-(BOOL) openDB;
-(void) closeDB;
-(NSString *)cDBNull;
-(NSString *)dbNullToEmptyString: (NSString *)theString;
-(BOOL) executeSQLCommand: (NSString *) commandText;
-(BOOL) doSelect: (NSString *) sql records: (NSMutableArray *_Nullable*_Nullable) recordList;
-(BOOL) doCommandWithParamsStart: (NSString *) sql;
-(BOOL) doCommandWithParamsAddParameterOfType: (NSString *) paramType paramValue: (NSString *) theParam;
-(BOOL) doCommandWithParamsEnd;



@end

NS_ASSUME_NONNULL_END
