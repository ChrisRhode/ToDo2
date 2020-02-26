//
//  MainListTableViewController.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

// ** reimplement delete as "hide" so Transaction Log works
// ** will also allow recovery of deleted items
// ** why does .m also have an interface section?
// ** All NSNumber casts/fixes
// ** auto vs forced reload deep understanding
// ** trnlog problem when text is edited, it shows the current itemtext value even in history
// ** maybe display friendly date at top of main controller?
// ** disable multiple scenes if enabled

// TrnLogManagerTableViewController is now used in two ways
//   (1) As a utility class for making all transaction log entries
//   (2) As a pushed view to display the transaction log contents
// This allows for better encapsulation of the transaction
// log type IDs and keeps the code in one place, since EditItem
// now also needs to do transaction log entries

#import "MainListTableViewController.h"
#import "EditItem.h"

@interface MainListTableViewController ()

@end

@implementation MainListTableViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSMutableArray *localRecords;
    
    refreshDueToEdit = NO;
    displayMode = 1;
    self.title = @"ToDo by Chris Rhode";
    
    // ** need to figure out why image could not be found in assets; also can JPEG/JPG be used instead of PNG
    // ** clearcolor not needed for tableView itself ??
    // ** using [x setyyy vs x.yyy =
    
    // later, tableview cells are set to background clearcolor so image shows behind them
    UIImageView *tmpv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DAT2.png"]];
    // ** understand the setFrame
    [tmpv setFrame:self.tableView.frame];
    tmpv.contentMode = UIViewContentModeCenter;
    tmpv.alpha = 0.05;
    self.tableView.backgroundView = tmpv;
                     
    UIBarButtonItem *tmp1 = [[UIBarButtonItem alloc] initWithTitle:@"TrnLog" style:UIBarButtonItemStylePlain target:self action:@selector(handleDisplayTrnLog)];
    self.navigationItem.rightBarButtonItems = @[tmp1]; // inserts right to left
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // this creates a search/text bar that is in the scolling area above the first real cell
    
    // * x origin, y origin, width, height
    
    searchOrAdd = [[UITextField alloc] initWithFrame:CGRectMake(0,0,320,44)];
    searchOrAdd.delegate = self;
    // * need this or it will look like the text box "isn't there"
    searchOrAdd.borderStyle = UITextBorderStyleRoundedRect;
    searchOrAdd.clearButtonMode = YES;
    searchOrAdd.placeholder = @"(search/add)";
    searchOrAdd.backgroundColor = [UIColor clearColor];
    [[self tableView] setTableHeaderView:searchOrAdd];
    
    // long press on a cell to edit that item
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
    
    db = [[DBWrapper alloc] initForDbFile:@"ToDoDb"];
    [db openDB];
    // ** test for status on things that return status / error handling
    // ** architecture for database schema updates
    // ** bump ordering vs fixed ordering
    // ** change InProgress to isInProgress
    // ** add trnlog discrete item field changes old and new
    
    [db executeSQLCommand:@"CREATE TABLE IF NOT EXISTS Items (SnapID INTEGER NOT NULL, NodeID INTEGER NOT NULL, ParentNodeID INTEGER NOT NULL, ChildCount INTEGER NOT NULL, ItemText TEXT NOT NULL, Notes TEXT, BumpCtr INTEGER NOT NULL, BumpToTopDate TEXT, isGrayedOut INTEGER NOT NULL, isDeleted INTEGER NOT NULL, PRIMARY KEY (SnapID, NodeID));"];
    [db executeSQLCommand:@"CREATE TABLE IF NOT EXISTS TrnLog (SeqNum INTEGER PRIMARY KEY, SnapID INTEGER NOT NULL, OpCode INTEGER NOT NULL, InProgress INTEGER, P1 INTEGER, P2 INTEGER);"];
    
    NSString *returnedValue;
     // * if no records in table, this will return a record with NULL value in column 0
    // ** NSString as "default type" for NSArray items?!
    
    [db doSelect:@"SELECT MAX(SnapID) FROM Items;" records:&localRecords];
    returnedValue = [[localRecords objectAtIndex:0] objectAtIndex:0];
    if ([returnedValue isEqualToString:[db cDBNull]])
    {
        currSnapID = 1;
    }
    else
    {
        currSnapID = [returnedValue integerValue];
    }
    
    [db doSelect:@"SELECT MAX(NodeID) FROM Items;" records:&localRecords];
    returnedValue = [[localRecords objectAtIndex:0] objectAtIndex:0];
    if ([returnedValue isEqualToString:[db cDBNull]])
    {
        currMaxNodeID = 0;
    }
    else
    {
        currMaxNodeID = [returnedValue integerValue];
    }
    [db closeDB];
    
    trnLogger = [[TrnLogManagerTableViewController alloc] initForUtilityWithCurrSnapID:currSnapID];
    
    levelStack = [[NSMutableArray alloc] init];
    NSArray *tmp;
    // levelStack: NSNumber ParentNodeID, NSString *ParentNodeText
    // ** handle or don't per row edits in browse vs search mode
   
    currParentNodeID = 0;
    currParentNodeText = @"$root$";
    tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:currParentNodeID] , currParentNodeText, nil];
    [levelStack addObject:tmp];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (refreshDueToEdit)
    {
        refreshDueToEdit = NO;
        [self loadOrReloadCurrentItemView:YES];
    }
    else
    {
        // ** event order/trigger on initial will appear
        [self loadOrReloadCurrentItemView:NO];
    }
    
}

-(void) handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath != nil)
        {
            NSArray *aRecord;
            NSUInteger row;
            row = [indexPath row];
            if (row == 0)
            {
                return;
            }
            // edit that row
            aRecord = [viewRecords objectAtIndex:(row-1)];
            
            EditItem *tmp = [[EditItem alloc] initForNodeID:[[aRecord objectAtIndex:0] integerValue] withCurrentSnapID:currSnapID];
            // *** (6)
            tmp.delegate = self;
            [[self navigationController] pushViewController:tmp animated:YES];
        }
    }
}

// *** (7)
-(void) doPassbackEditItem: (BOOL) wasCancelled
{
   
    // ** order/side effects -- viewWillAppear will fire, implied refresh?
    refreshDueToEdit = !wasCancelled;
    [self.navigationController popViewControllerAnimated:NO];
}

-(void) loadOrReloadCurrentItemView:(BOOL) forceReload
{
    NSString *sql;
    NSMutableArray *localRecords;
    
    // ** nullable yes or no on records return
    // ** partial index use of primary key / indexes on other fields
    // ** full text indexing on ItemText?
    // ** disallow empty ItemText in all cases
    // ** use isXXX or isNotxxxx for booleans as DB field names
    // ** ability to show/purge deleted items ... may create holes in NodeID including at end
    
    [db openDB];
    sql = @"SELECT NodeID,ChildCount,ItemText,isGrayedOut FROM Items WHERE (SnapID = ";
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") AND (ParentNodeID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currParentNodeID]];
    sql = [sql stringByAppendingString:@") AND (isDeleted = 0) ORDER BY BumpCtr DESC,NodeID;"];
    // * have to use variable local to this scope then copy to instance variable
    [db doSelect:sql records:&localRecords];
    [db closeDB];
    // ** can viewRecords be non Mutable?  what is common convention?
    viewRecords = [localRecords mutableCopy];
    if (forceReload)
    {
        [self.tableView reloadData];
    }
}

-(void)handleDisplayTrnLog

{
    TrnLogManagerTableViewController *tmp = [[TrnLogManagerTableViewController alloc] initForViewWithCurrSnapID:currSnapID];
    [[self navigationController] pushViewController:tmp animated:YES];
    // ** any special handling for "back via back button"?
    // ** fix EditItem so back via back button does the right things ... treat as OK or Cancel?
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tmpRecord;
    NSInteger childCount;
    
    NSUInteger row;
    row = [indexPath row];
    
    // top row allows go to root, if not at root now
    // ** disallow if in search mode?
    // ** handlers should return YES or NO ?!
    
    if (row == 0)
    {
        if (currParentNodeID == 0)
        {
            return nil;
        }
        UIContextualAction *aRoot;
        
        aRoot = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Go to Root" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            NSArray *tmp;
            self->currParentNodeID = 0;
            self->currParentNodeText = @"$root$";
            tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:(self->currParentNodeID)] , self->currParentNodeText, nil];
            [self->levelStack removeAllObjects];
            [self->levelStack addObject:tmp];
            [self loadOrReloadCurrentItemView:YES];
            
        }];
        
        aRoot.backgroundColor = [UIColor greenColor];
        
        UISwipeActionsConfiguration *actions;
        
        actions = [UISwipeActionsConfiguration configurationWithActions:@[aRoot]];
        
        return actions;
    }
    
    // ** displayMode implementation for other cells
    //  1 = normal (Bump, Delete If no children, Gray/Ungray)
    //  2 = search/add in progress (none allowed)
    
    tmpRecord = [self->viewRecords objectAtIndex:(row-1)];
    childCount = [(NSString *)[tmpRecord objectAtIndex:1] integerValue];
    
    UIContextualAction *aBump,*aDelete,*aGray;
    // * instance vs class methods
    
    if (displayMode != 2)
    {
        aBump = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Bump" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            NSInteger nodeID;
            NSArray *aRecord;
            NSString *sql;
            // * understand use of self
             // ** () usage for self-> as example
            
            aRecord = [self->viewRecords objectAtIndex:(row-1)];
            // ** use intValue for NSNumbers, not integerValue
            // ** check for use of string decode for all fields always
            // ** consistent use of ; at end of SQL statements
            nodeID = [(NSString *)[aRecord objectAtIndex:0] integerValue];
            
            [self->trnLogger logStartBumpTransactionOfNodeID:nodeID];
            [self->db openDB];

            sql = @"UPDATE Items SET BumpCtr = BumpCtr + 1";
            sql = [sql stringByAppendingString:@" WHERE (SnapID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
            sql = [sql stringByAppendingString:@") AND (NodeID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)nodeID]];
            sql = [sql stringByAppendingString:@");"];
            [self->db executeSQLCommand:sql];
            [self->db closeDB];
            [self->trnLogger logEndTransaction];
            [self loadOrReloadCurrentItemView:YES];
        }];
        aBump.backgroundColor = [UIColor orangeColor];
        
        if (childCount == 0)
        {
            aDelete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                
                NSInteger nodeID;
                NSArray *aRecord;
                NSString *sql;
                
                aRecord = [self->viewRecords objectAtIndex:(row-1)];
                nodeID = [(NSString *)[aRecord objectAtIndex:0] integerValue];
                
                [self->trnLogger  logStartDeleteTransactionOfNodeID:nodeID];
                [self->db openDB];
                
                sql = @"UPDATE Items SET isDeleted = 1 WHERE (SnapID = ";
                sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
                sql = [sql stringByAppendingString:@") AND (NodeID = "];
                sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)nodeID]];
                sql = [sql stringByAppendingString:@");"];
                [self->db executeSQLCommand:sql];
                
                if (self->currParentNodeID != 0)
                {
                    sql = @"UPDATE Items SET ChildCount = ChildCount - 1 WHERE (SnapID = ";
                    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
                    sql = [sql stringByAppendingString:@") AND (NodeID = "];
                    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currParentNodeID)]];
                    sql = [sql stringByAppendingString:@");"];
                    [self->db executeSQLCommand:sql];
                }
                
                [self->db closeDB];
                [self->trnLogger logEndTransaction];
                [self loadOrReloadCurrentItemView:YES];
            }];
            aDelete.backgroundColor = [UIColor redColor];
        }
        
        aGray = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            NSInteger nodeID;
            NSArray *aRecord;
            NSString *sql;
            
            aRecord = [self->viewRecords objectAtIndex:(row-1)];
            // ** use intValue for NSNumbers, not integerValue
            nodeID = [(NSString *)[aRecord objectAtIndex:0] integerValue];
            
            [self->trnLogger  logStartGrayToggleTransactionOfNodeID:nodeID newStateIsGray:(1-[(NSString *)[aRecord objectAtIndex:3] integerValue] == 1)];
            [self->db openDB];
            
            sql = @"UPDATE Items SET isGrayedOut = 1 - isGrayedOut ";
            sql = [sql stringByAppendingString:@" WHERE (SnapID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
            sql = [sql stringByAppendingString:@") AND (NodeID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)nodeID]];
            sql = [sql stringByAppendingString:@");"];
            [self->db executeSQLCommand:sql];
            [self->db closeDB];
            [self->trnLogger logEndTransaction];
            [self loadOrReloadCurrentItemView:YES];
        }];
        aGray.backgroundColor = [UIColor lightGrayColor];
        BOOL newGrayState;
        newGrayState = (1-[(NSString *)[tmpRecord objectAtIndex:3] integerValue] == 1);
        if (newGrayState)
        {
            aGray.title = @"Gray";
        }
        else
        {
            aGray.title = @"Ungray";
        }
        
        // Now return all the appropriate swipe actions
        UISwipeActionsConfiguration *actions;
        
        // ** may eventually want to allow delete of node with children
        if (childCount != 0)
        {
            actions = [UISwipeActionsConfiguration configurationWithActions:@[aBump,aGray]];
        }
        else
        {
            actions = [UISwipeActionsConfiguration configurationWithActions:@[aDelete,aBump,aGray]];
        }
        
        return actions;
    }
    else
    {
        return nil;
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [viewRecords count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    NSArray *aRecord;
    
    // Configure the cell...
    // ** reusable cell stuff, is this the new auto way?
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MainListCell"];
    
    // * needed for background image to show through cells
    cell.backgroundColor = [UIColor clearColor];
    
    NSUInteger row;
    row = [indexPath row];
    if (row == 0)
    {
        cell.textLabel.text = [@"(" stringByAppendingString:[currParentNodeText stringByAppendingString:@")"]];
    }
    else
    {
        
        aRecord = [viewRecords objectAtIndex:(row-1)];
        cell.textLabel.text = [aRecord objectAtIndex:2];
        
        // display disclosure if it has children
        if ([[aRecord objectAtIndex:1] integerValue] == 0)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        // if it is set Grayed, make it gray
        if ([[aRecord objectAtIndex:3] integerValue] == 1)
        {
            cell.backgroundColor = [UIColor lightGrayColor];
        }
    }
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ** handle if node tapped during incremental search
    NSUInteger row;
    NSArray *aRecord;
    
    row = [indexPath row];
    
    if (row == 0) // if tap here go back to previous level
    {
        if ([levelStack count] == 1)
        {
            // do nothing
        }
        else
        {
            NSArray *tmp;
            tmp = [levelStack objectAtIndex:([levelStack count]-2)];
            
            currParentNodeID = [(NSNumber *)[tmp objectAtIndex:0] intValue];
            currParentNodeText = [tmp objectAtIndex:1];
            [levelStack removeLastObject];
            [self loadOrReloadCurrentItemView:YES];
        }
    }
    else // descend to that node as new parent
    {
        aRecord = [viewRecords objectAtIndex:(row-1)];
        switch(displayMode)
        {
            case 1:
            {
                // normal
                currParentNodeID = [[aRecord objectAtIndex:0] integerValue];
                currParentNodeText = [aRecord objectAtIndex:2];
                NSArray *tmp;
                tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:currParentNodeID] , currParentNodeText, nil];
                [levelStack addObject:tmp];
                [self loadOrReloadCurrentItemView:YES];
                break;
            }
            case 2:
            {
                // we are in search mode
                // have to rebuild the levelStack based on this node
                NSMutableArray *reverseStack;
                NSMutableArray *localRecords;
                NSInteger nodeID;
                NSString *nodeText;
                NSArray *tmp;
                NSString *sql;
                BOOL stop;
                
                reverseStack = [[NSMutableArray alloc] init];
                nodeID = [[aRecord objectAtIndex:0] integerValue];;
                nodeText = [aRecord objectAtIndex:2];
                tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:nodeID] , nodeText, nil];
                [reverseStack addObject:tmp];
                // now walk up all parents
                [db openDB];
                stop = NO;
                do
                {
                    // get parent of current node
                    sql = @"SELECT ParentNodeID FROM Items WHERE (SnapID = ";
                     sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
                      sql = [sql stringByAppendingString:@") AND (NodeID = "];
                      sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld",  (long)nodeID]];
                    sql = [sql stringByAppendingString:@")"];
                      [db doSelect:sql records:&localRecords];
                    nodeID = [[[localRecords objectAtIndex:0] objectAtIndex:0] integerValue];
                    if (nodeID != 0)
                    {
                        sql = @"SELECT ItemText FROM Items WHERE (SnapID = ";
                        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
                        sql = [sql stringByAppendingString:@") AND (NodeID = "];
                        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld",  (long)nodeID]];
                        sql = [sql stringByAppendingString:@")"];
                        [db doSelect:sql records:&localRecords];
                        nodeText = [[localRecords objectAtIndex:0] objectAtIndex:0];
                        tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:nodeID] , nodeText, nil];
                        [reverseStack addObject:tmp];
                    }
                    else
                    {
                        nodeText = @"$root$";
                        tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:nodeID] , nodeText, nil];
                        [reverseStack addObject:tmp];
                        stop = YES;
                    }
                } while (!stop);
                  [db closeDB];
                // reverse the order but first item is the new parent
                NSInteger idx;
                NSInteger startIdx;
                [levelStack removeAllObjects];
                startIdx = [reverseStack count] - 1;
                if (startIdx > 1)
                {
                    for (idx = startIdx;idx>=1;idx--)
                    {
                        [levelStack addObject:[reverseStack objectAtIndex:idx]];
                    }
                }
                NSArray *tmp2;
                tmp2 = [reverseStack objectAtIndex:0];
                
                currParentNodeID = [(NSNumber *)[tmp2 objectAtIndex:0] intValue];
                currParentNodeText = [tmp2 objectAtIndex:1];
                displayMode = 1;
                searchOrAdd.text = @"";
                [self loadOrReloadCurrentItemView:YES];
                
                break;
            }
            default:
                // ** exception for default clauses
            {
                break;
            }
        }
    }
}

-(void)textFieldDidChangeSelection:(UITextField *)textField
{
    NSString *tmp;
    
    tmp = textField.text;
    if ([tmp length] >=2) // only search if there are > 1 chars entered
    {
        NSString *sql;
        NSMutableArray *localRecords;
        [db openDB];
        
        sql = @"SELECT NodeID,ChildCount,ItemText,isGrayedOut FROM Items WHERE (ItemText LIKE '%";
        sql = [sql stringByAppendingString:tmp];
        sql = [sql stringByAppendingString:@"%') AND (SnapID = "];
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
        sql = [sql stringByAppendingString:@") ORDER BY NodeID;"];
        // have to use variable local to this scope then copy to instance variable
        [db doSelect:sql records:&localRecords];
        [db closeDB];
        viewRecords = [localRecords mutableCopy];
        displayMode = 2;
        [self.tableView reloadData];
    }
    else
    {
        [self loadOrReloadCurrentItemView:YES];
        displayMode = 1;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // treat as ADD
    NSString *tmp;
    tmp = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([tmp isEqualToString:@""])
    {
        return NO;
    }
    // ** check for status returns and do exception handling
    // ** convert to virtual operations (for undo, transaction verification etc.
    
    [trnLogger logStartAddTransactionOfNodeID:(currMaxNodeID+1) parentNodeID:currParentNodeID];
    [db openDB];
    
    [db doCommandWithParamsStart:@"INSERT INTO Items VALUES (?,?,?,0,?,NULL,0,NULL,0,0);"];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    currMaxNodeID += 1;
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)currMaxNodeID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)currParentNodeID]];
    [db doCommandWithParamsAddParameterOfType:@"S" paramValue:tmp];
    [db doCommandWithParamsEnd];
    // update ChildCount for parent
    if (currParentNodeID != 0)
    {
        NSString *sql;
        
        sql = @"UPDATE Items SET ChildCount = ChildCount + 1 WHERE (SnapID = ";
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
        sql = [sql stringByAppendingString:@") AND (NodeID = "];
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currParentNodeID]];
        sql = [sql stringByAppendingString:@");"];
        [db executeSQLCommand:sql];
    }
    
    [db closeDB];
    [trnLogger logEndTransaction];
    
    textField.text = @"";
    [textField resignFirstResponder];
    // ** apparently list refrehes without need to force it?
    displayMode = 1;
    // ** displayMode management after add
    [self loadOrReloadCurrentItemView:YES];
    
    return NO;
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
