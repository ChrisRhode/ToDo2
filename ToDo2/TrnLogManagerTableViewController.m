//
//  TrnLogManagerTableViewController.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/22/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "TrnLogManagerTableViewController.h"

@interface TrnLogManagerTableViewController ()

@end

@implementation TrnLogManagerTableViewController

-(id) initForViewWithCurrSnapID: (NSInteger) snapID

{
    if (self = [super init])
       {
           currSnapID = snapID;
           
           return self;
       }
       else
       {
           return nil;
       }
}

-(id) initForUtilityWithCurrSnapID: (NSInteger) snapID
{
    if (self = [super init])
    {
        NSMutableArray *localRecords;
        NSString *returnedValue;
        
        currSnapID = snapID;
        
        db = [[DBWrapper alloc] initForDbFile:@"ToDoDb"];
        
        [db openDB];
        [db doSelect:@"SELECT MAX(SeqNum) FROM TrnLog;" records:&localRecords];
        returnedValue = [[localRecords objectAtIndex:0] objectAtIndex:0];
        if ([returnedValue isEqualToString:[db cDBNull]])
        {
            currMaxTrnLogSeqNum = 0;
        }
        else
        {
            currMaxTrnLogSeqNum = [returnedValue integerValue];
        }
        [db closeDB];
        
        return self;
    }
    else
    {
        return nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // ** make sure this does not fire when used as utility
    self.title = @"Transaction Log";
    db = [[DBWrapper alloc] initForDbFile:@"ToDoDb"];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *sql;
    NSMutableArray *localRecords;
    
    [db openDB];
    sql = @"SELECT A.OpCode,A.P1,A.P2,B.ItemText,C.ItemText,A.InProgress,A.ChgData FROM TrnLog A LEFT OUTER JOIN Items B ON (B.NodeID = A.P1) AND (B.SnapID = ";
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") LEFT OUTER JOIN Items C ON (C.NodeID = A.P2) AND (C.SnapID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") WHERE (A.SnapID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") ORDER BY A.SeqNum DESC;"];
    // have to use variable local to this scope then copy to instance variable
    [db doSelect:sql records:&localRecords];
    [db closeDB];
    viewRecords = [localRecords mutableCopy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [viewRecords count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    NSArray *aRecord;
    NSInteger opCode;
    NSString *display;
    NSInteger P2;
    // Configure the cell...
   
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TrnLogCell"];
    cell.detailTextLabel.text = @"";
    
    NSUInteger row;
    row = [indexPath row];
    
    aRecord = [viewRecords objectAtIndex:row];
    opCode = [[aRecord objectAtIndex:0] integerValue];
    
    switch (opCode)
    {
        case 1:
        {
            display = @"Add '";
            display = [display stringByAppendingString:[aRecord objectAtIndex:3]];
            display = [display stringByAppendingString:@"' to "];
            P2 = [[aRecord objectAtIndex:2] integerValue];
            if (P2 == 0)
            {
                display = [display stringByAppendingString:@"root"];
            }
            else
            {
                display = [display stringByAppendingString:@"'"];
                display = [display stringByAppendingString:[aRecord objectAtIndex:4]];
                display = [display stringByAppendingString:@"'"];
            }
            break;
        }
        case 2:
        {
            display = @"Delete '";
            display = [display stringByAppendingString:[aRecord objectAtIndex:3]];
            display = [display stringByAppendingString:@"'"];
            
            break;
        }
        case 3:
        {
            display = @"Bump priority of '";
            display = [display stringByAppendingString:[aRecord objectAtIndex:3]];
            display = [display stringByAppendingString:@"'"];
            
            break;
        }
        case 4:
        {
            P2 = [[aRecord objectAtIndex:2] integerValue];
            if (P2 == 0)
            {
                display = @"UnGrayOut '";
            }
            else
            {
                display = @"GrayOut '";
            }
            display = [display stringByAppendingString:[aRecord objectAtIndex:3]];
            display = [display stringByAppendingString:@"'"];
            
            break;
        }
        case 5:
            // change data blob is in column 6
        {
            display = @"Edited '";
            display = [display stringByAppendingString:[aRecord objectAtIndex:3]];
            display = [display stringByAppendingString:@"'"];
            //
            NSArray *chgData;
            NSString *detail;
            detail = @"";
            if (![[aRecord objectAtIndex:6] isEqualToString:[db cDBNull]])
            {
                chgData =  [[aRecord objectAtIndex:6] componentsSeparatedByString:@":"];
                NSString *old,*new;
                old = [chgData objectAtIndex:0];
                new = [chgData objectAtIndex:1];
                NSArray *oldItems,*newItems;
                oldItems = [old componentsSeparatedByString:@"|"];
                newItems = [new componentsSeparatedByString:@"|"];
                
                if (![[oldItems objectAtIndex:0] isEqualToString:[newItems objectAtIndex:0]])
                {
                    detail = @"ItemText";
                }
                
                if (![[oldItems objectAtIndex:1] isEqualToString:[newItems objectAtIndex:1]])
                {
                    if (![detail isEqualToString:@""])
                    {
                        detail = [detail stringByAppendingString:@","];
                    }
                    detail = [detail stringByAppendingString:@"Notes"];
                }
                if (![[oldItems objectAtIndex:2] isEqualToString:[newItems objectAtIndex:2]])
                {
                    if (![detail isEqualToString:@""])
                    {
                        detail = [detail stringByAppendingString:@","];
                    }
                    detail = [detail stringByAppendingString:@"BumpCtr"];
                }
                if (![[oldItems objectAtIndex:3] isEqualToString:[newItems objectAtIndex:3]])
                {
                    if (![detail isEqualToString:@""])
                    {
                        detail = [detail stringByAppendingString:@","];
                    }
                    detail = [detail stringByAppendingString:@"BumpToTopDate"];
                }
                if (![[oldItems objectAtIndex:4] isEqualToString:[newItems objectAtIndex:4]])
                {
                    if (![detail isEqualToString:@""])
                    {
                        detail = [detail stringByAppendingString:@","];
                    }
                    detail = [detail stringByAppendingString:@"DateOfEvent"];
                }
                cell.detailTextLabel.text = detail;
            }
            
            //
            break;
        }
        default:
        {
            display = @"Error!";
            
            break;
        }
    }
    
    if ([[aRecord objectAtIndex:5] integerValue] == 1)
    {
        display = [display stringByAppendingString:@" (INCOMPLETE!)"];
    }
    
    cell.textLabel.text = display;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

-(void) logStartAddTransactionOfNodeID : (NSInteger) newNodeID parentNodeID: (NSInteger) theParentNodeID
{
    
    currMaxTrnLogSeqNum +=1;
    
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO TrnLog VALUES (?,?,?,?,?,?,NULL);"];
    
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currMaxTrnLogSeqNum]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)newNodeID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)theParentNodeID]];
    [db doCommandWithParamsEnd];
    [db closeDB];
    
}

-(void) logStartDeleteTransactionOfNodeID : (NSInteger) nodeID
{
    
    currMaxTrnLogSeqNum +=1;
    
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO TrnLog VALUES (?,?,?,?,?,NULL,NULL);"];
    
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currMaxTrnLogSeqNum]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(2)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)nodeID]];
    [db doCommandWithParamsEnd];
    [db closeDB];
}

-(void) logStartBumpTransactionOfNodeID : (NSInteger) nodeID
{
    
    currMaxTrnLogSeqNum +=1;
    
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO TrnLog VALUES (?,?,?,?,?,NULL,NULL);"];
    
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currMaxTrnLogSeqNum]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(3)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)nodeID]];
    [db doCommandWithParamsEnd];
    [db closeDB];
}

-(void) logStartGrayToggleTransactionOfNodeID : (NSInteger) nodeID newStateIsGray: (BOOL) theNewStateIsGray
{
    
    currMaxTrnLogSeqNum +=1;
    
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO TrnLog VALUES (?,?,?,?,?,?,NULL);"];
    
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currMaxTrnLogSeqNum]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(4)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)nodeID]];
    if (theNewStateIsGray)
    {
   
     [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
      }
    else
    {
          [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(0)]];
    }
    
    [db doCommandWithParamsEnd];
    [db closeDB];
}

-(void) logStartEditTransactionOfNodeID : (NSInteger) nodeID withChangeData : (NSString *) theChangeData
{

    currMaxTrnLogSeqNum +=1;
    
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO TrnLog VALUES (?,?,?,?,?,NULL,?);"];
    
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currMaxTrnLogSeqNum]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(5)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)(1)]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)nodeID]];
     [db doCommandWithParamsAddParameterOfType:@"NS" paramValue:theChangeData];
    [db doCommandWithParamsEnd];
    [db closeDB];
}
-(void) logEndTransaction
{
    NSString *sql;
    
    [db openDB];
    sql = @"UPDATE TrnLog SET InProgress = 0";
    sql = [sql stringByAppendingString:@" WHERE (SeqNum = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currMaxTrnLogSeqNum]];
    sql = [sql stringByAppendingString:@");"];
    [db executeSQLCommand:sql];
    [db closeDB];
}

// template from here to end

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
