//
//  DBMgr.m
//  ToDo2
//
//  Created by Christopher Rhode on 4/21/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "DBMgr.h"

@interface DBMgr ()

@end

@implementation DBMgr

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    currSnapID = 1;
    db = [[DBWrapper alloc] initForDbFile:@"ToDoDb"];
    ugbl = [[Utility alloc] init];
    _txtviewOutput.text = @"";
}

-(void) addToOutput: (NSString *) theString
{
    _txtviewOutput.text = [_txtviewOutput.text stringByAppendingString:theString];
}

-(void) EOLOutput
{
    _txtviewOutput.text = [_txtviewOutput.text stringByAppendingString:@"\n"];
}

- (IBAction)btnHandleConsistencyCheck:(id)sender {
    // *** handle empty DB
    // *** validate childCount at each level
    
    NSArray *localRecords;
    
    bool check;
    NSString *sql;
    NSInteger nbrOfNodes;
    NSInteger ndx;
    NSInteger lastNdx,lastNdx2;
    NSInteger aNodeID;
    
    _txtviewOutput.text = @"";
    
    [db openDB];
    sql = @"SELECT MAX(NodeID) FROM Items WHERE (SnapID =";
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@")"];
    [db doSelect:sql records:&localRecords];
    nbrOfNodes = [[[localRecords objectAtIndex:0] objectAtIndex:0] integerValue];
    
    [self addToOutput:@"START DB CONSISTENCY CHECK"];
    [self EOLOutput];
    [self addToOutput:@"Expected total node count: "];
    [self addToOutput:[NSString stringWithFormat:@"%ld", (long)nbrOfNodes]];
    [self EOLOutput];
    
    seen = [[NSMutableArray alloc] init];
    lastNdx = nbrOfNodes - 1;
    for (ndx = 0; ndx <= lastNdx; ndx ++)
    {
        [seen addObject:@"N"];
    }
    seenCount = [seen count];
    
    check = [self checkARoot:0 withExpectedChildCount:-1 andLevel:0];
    
    // mark up the deleted nodes
    sql = @"SELECT NodeID,ItemText FROM Items WHERE (SnapID =";
       sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
       sql = [sql stringByAppendingString:@") AND (isDeleted = 1)"];
       [db doSelect:sql records:&localRecords];
    lastNdx2 = [localRecords count] - 1;
    for (ndx = 0; ndx <= lastNdx2; ndx ++)
    {
        aNodeID = [[[localRecords objectAtIndex:ndx] objectAtIndex:0] integerValue];
        [seen setObject:@"Y" atIndexedSubscript:(aNodeID - 1)];
        [self addToOutput:@"(DELETED)"];
        [self addToOutput:[[localRecords objectAtIndex:ndx] objectAtIndex:1]];
        [self EOLOutput];
    }
    
    [self addToOutput:@"END DB CONSISTENCY CHECK"];
    [self EOLOutput];
    
    if (check)
    {
        for (ndx = 0; ndx <= lastNdx; ndx ++)
        {
            if ([[seen objectAtIndex:ndx] isEqualToString:@"N"])
            {
                [ugbl displayPopUpAlert:@"Error" withMessage:@"Not all nodes were seen"];
                break;
            }
        }
        [ugbl displayPopUpAlert:@"Success" withMessage:@"Database is okay!"];
    }
    else
    {
       [ugbl displayPopUpAlert:@"Error" withMessage:@"Database has consistency issues"];
    }
    [db closeDB];
}

-(BOOL) checkARoot: (NSInteger) theRootNodeID withExpectedChildCount: (NSInteger) expectedChildCount andLevel: (NSInteger) theLevel
{
    NSString *sql;
    NSArray *localRecords;
    NSInteger ndx,ndx2;
    NSInteger lastNdx;
    NSInteger thisNodeID;
    NSInteger thisNodeChildCount;
    BOOL check;
    
    sql = @"SELECT NodeID,ChildCount,ItemText FROM Items WHERE (SnapID = ";
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") AND (ParentNodeID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)theRootNodeID]];
    sql = [sql stringByAppendingString:@") AND (isDeleted = 0)"];
    [db doSelect:sql records:&localRecords];
    if (expectedChildCount != -1)
    {
        if ([localRecords count] != expectedChildCount)
        {
            [self addToOutput:@"ERROR, wrong child node count ("];
            [self addToOutput:[NSString stringWithFormat:@"%ld", (long)[localRecords count]]];
            [self addToOutput:@") expected ("];
            [self addToOutput:[NSString stringWithFormat:@"%ld", (long)[localRecords count]]];
            [self EOLOutput];
            return NO;
        }
    }
    lastNdx = [localRecords count] - 1;
    for (ndx = 0; ndx <= lastNdx; ndx++)
    {
        thisNodeID = [[[localRecords objectAtIndex:ndx] objectAtIndex:0] integerValue];
        thisNodeChildCount = [[[localRecords objectAtIndex:ndx] objectAtIndex:1] integerValue];
        if (thisNodeID > seenCount)
        {
            [self addToOutput:@"ERROR, invalid NodeID ("];
            [self addToOutput:[NSString stringWithFormat:@"%ld", (long)thisNodeID]];
            [self addToOutput:@") encountered"];
            [self EOLOutput];
            return NO;
        }
        if (![[seen objectAtIndex:(thisNodeID-1)] isEqualToString:@"N"])
        {
            [self addToOutput:@"ERROR, NodeID ("];
            [self addToOutput:[NSString stringWithFormat:@"%ld", (long)thisNodeID]];
            [self addToOutput:@") seen more than once"];
            [self EOLOutput];
            return NO;
        }
        [seen setObject:@"Y" atIndexedSubscript:(thisNodeID - 1)];
        
        for (ndx2 = 0; ndx2 < theLevel; ndx2++)
           {
               [self addToOutput:@"."];
           }
           [self addToOutput:[[localRecords objectAtIndex:ndx] objectAtIndex:2]];
           [self EOLOutput];
        
        if (thisNodeChildCount > 0)
        {
            check = [self checkARoot:thisNodeID withExpectedChildCount:thisNodeChildCount andLevel:(theLevel+1)];
            if (!check)
            {
                return NO;
            }
        }
    }
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
