//
//  DBWrapper.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "DBWrapper.h"


@implementation DBWrapper

-(id) initForDbFile: (NSString *) fileNameWithoutPath
{
    if (self = [super init])
    {
        NSString *tmp;
        
        ugbl = [[Utility alloc] init];
        tmp = [ugbl getDocumentsDirectory];
        fullPathToDBDFile = [[tmp stringByAppendingString:fileNameWithoutPath] stringByAppendingString:@".sqlite"];
        
        return self;
    }
    else
    {
        return nil;
    }
}

-(NSString *)cDBNull
{
    return @"$db$N$u$L$L";
}

-(NSString *)dbNullToEmptyString: (NSString *)theString
{
    if ([theString isEqualToString:[self cDBNull]])
    {
        return @"";
    }
    else
    {
        return theString;
    }
}

-(BOOL) openDB
{
    int status;
    
    status = sqlite3_open([fullPathToDBDFile UTF8String],&db);
    if (status != SQLITE_OK)
    {
       // per textbook do a close even if the open didn't open it
        
        sqlite3_close(db);
        return NO;
    }
    else
    {
         return YES;
    }

}

-(void) closeDB
{
    sqlite3_close(db);
}

-(BOOL) executeSQLCommand: (NSString *) commandText
{
    char *errorMsg;
    int status;
    
    status = sqlite3_exec(db,[commandText UTF8String],NULL,NULL,&errorMsg);
    if (status != SQLITE_OK)
    {
        return NO;
    }
    
    return YES;
}

/* bind columns for insert 1 based, get columns for select 0 based ?! */

-(BOOL) doSelect: (NSString *) sql records: (NSMutableArray *_Nullable*_Nullable) recordList
{
    NSUInteger idx;
    NSUInteger lastNdx;
    NSMutableArray *thisRecord;
    sqlite3_stmt *stmt;
    int status;
    int param_int;
    char *param_text;
    NSString *tmp_string;
    NSMutableArray *local_record_list;
    
    int columnType;
    
    local_record_list = [[NSMutableArray alloc] init];
    
    status = sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmt, nil);
    if (status != SQLITE_OK)
    {
        return NO;
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW)
    {
        // deep understand how this is retained down here when used up there in array
        thisRecord = [[NSMutableArray alloc] init];
        lastNdx = sqlite3_column_count(stmt) - 1;
        for (idx = 0; idx <= lastNdx; idx++)
           {
               // ** 0 indexing vs 1 indexing
               columnType = sqlite3_column_type(stmt,(int)idx);
               if (columnType == SQLITE_NULL)
               {
                    [thisRecord addObject:[self cDBNull]];
               }
               else if (columnType == SQLITE_INTEGER)
               {
                   param_int = sqlite3_column_int(stmt,(int)idx);
                   [thisRecord addObject:[NSString stringWithFormat:@"%ld", (long)param_int]];
               }
               else if (columnType == SQLITE_TEXT)
               {
                   param_text = (char *)sqlite3_column_text(stmt,(int)idx);
                   tmp_string = [NSString stringWithUTF8String:param_text];
                   [thisRecord addObject:tmp_string];
               }
               else
               {
                   return NO;
               }
                   
           }
        [local_record_list addObject:thisRecord];
    }
    sqlite3_finalize(stmt);
    
    // this may be wrong/bad
    
    *recordList = local_record_list;
    
    return YES;
}

-(BOOL) doCommandWithParamsStart: (NSString *) sql
{
    int status;
    
    status = sqlite3_prepare_v2(db, [sql UTF8String], -1, &stmtForParamCommand, nil);
    if (status != SQLITE_OK)
    {
        return NO;
    }
    
    insertParamCtr = 0;
    return YES;
}

-(BOOL) doCommandWithParamsAddParameterOfType: (NSString *) paramType paramValue: (NSString *) theParam
{
    
    if ([paramType isEqualToString:@"S"])
    {
        insertParamCtr += 1;
        sqlite3_bind_text(stmtForParamCommand,(int)insertParamCtr,[theParam UTF8String],-1,NULL);
    }
    else if ([paramType isEqualToString:@"NS"])
    {
        insertParamCtr += 1;
        if ([theParam isEqualToString:@""])
        {
            sqlite3_bind_null(stmtForParamCommand,(int)insertParamCtr);
        }
        else
        {
            sqlite3_bind_text(stmtForParamCommand,(int)insertParamCtr,[theParam UTF8String],-1,NULL);
        }
    }
    else if ([paramType isEqualToString:@"I"])
    {
        insertParamCtr += 1;
        sqlite3_bind_int(stmtForParamCommand,(int)insertParamCtr,(int)[theParam integerValue]);
    }
    else if ([paramType isEqualToString:@"NI"])
    {
        insertParamCtr += 1;
        if ([theParam isEqualToString:@""])
        {
            sqlite3_bind_null(stmtForParamCommand,(int)insertParamCtr);
        }
        else
        {
            sqlite3_bind_int(stmtForParamCommand,(int)insertParamCtr,(int)[theParam integerValue]);
        }
    }
    else
    {
        return NO;
    }
    
    return YES;
}

-(BOOL) doCommandWithParamsEnd
{
    if (sqlite3_step(stmtForParamCommand) != SQLITE_DONE)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

@end
