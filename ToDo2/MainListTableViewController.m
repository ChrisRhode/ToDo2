//
//  MainListTableViewController.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//
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
    
    ugbl = [[Utility alloc] init];
    
    // ****** testing
    //NSString *tstring;
   // tstring = [ugbl dateToAugmentedHumanDate:[NSDate date]];
   // NSDate *d;
   // d = [ugbl dateAugmentedHumanDateToDate:tstring];
//    NSString *tstring;
//    tstring = @"Hello|W%orld|";
//    tstring = [ugbl encodeString:tstring toAvoidCharacters:@"|"];
//    tstring = [ugbl decodeString:tstring];
//
    //
    refreshDueToEdit = NO;
    displayMode = 1;
    //self.title = @"ToDo by Chris Rhode";
        
    // later, tableview cells are set to background clearcolor so image shows behind them
    UIImageView *tmpv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DAT2.png"]];
    [tmpv setFrame:self.tableView.frame];
    tmpv.contentMode = UIViewContentModeCenter;
    tmpv.alpha = 0.05;
    self.tableView.backgroundView = tmpv;
            
    [self setTopButtons];
    
  
    
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
   
    [db executeSQLCommand:@"CREATE TABLE IF NOT EXISTS Items (SnapID INTEGER NOT NULL, NodeID INTEGER NOT NULL, ParentNodeID INTEGER NOT NULL, ChildCount INTEGER NOT NULL, ItemText TEXT NOT NULL, Notes TEXT, BumpCtr INTEGER NOT NULL, BumpToTopDate TEXT, DateOfEvent TEXT, isGrayedOut INTEGER NOT NULL, isDeleted INTEGER NOT NULL, PRIMARY KEY (SnapID, NodeID))"];
    // 1.0 to 1.1
    if (![db columnExists:@"DateOfEvent" inTable:@"Items"])
    {
        [db executeSQLCommand:@"ALTER TABLE Items ADD COLUMN DateOfEvent TEXT"];
        [ugbl displayPopUpAlert:@"New feature!" withMessage:@"DateOfEvent now suppported for all items!"];
    }
    [db executeSQLCommand:@"CREATE TABLE IF NOT EXISTS TrnLog (SeqNum INTEGER PRIMARY KEY, SnapID INTEGER NOT NULL, OpCode INTEGER NOT NULL, InProgress INTEGER, P1 INTEGER, P2 INTEGER,ChgData TEXT)"];
    // 1.1 to 1.2
       if (![db columnExists:@"ChgData" inTable:@"TrnLog"])
       {
           [db executeSQLCommand:@"ALTER TABLE TrnLog ADD COLUMN ChgData TEXT"];
           [ugbl displayPopUpAlert:@"New feature!" withMessage:@"Moving forward, changes to items are now identified more precisely in the Transaction Log"];
       }
    
    NSString *returnedValue;
     // * if no records in table, this will return a record with NULL value in column 0
    
    [db doSelect:@"SELECT MAX(SnapID) FROM Items" records:&localRecords];
    returnedValue = [[localRecords objectAtIndex:0] objectAtIndex:0];
    if ([returnedValue isEqualToString:[db cDBNull]])
    {
        currSnapID = 1;
    }
    else
    {
        currSnapID = [returnedValue integerValue];
    }
    
    [db doSelect:@"SELECT MAX(NodeID) FROM Items" records:&localRecords];
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
   
    currParentNodeID = 0;
    currParentNodeText = @"$root$";
    tmp = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:currParentNodeID] , currParentNodeText, nil];
    [levelStack addObject:tmp];
}

-(void) setTopButtons
{
    NSString *lbl;
    if (displayMode == 3)
    {
        lbl = @"->Items";
    }
    else
    {
        lbl = @"->Dates";
    }
    
    UIBarButtonItem *tmp1 = [[UIBarButtonItem alloc] initWithTitle:@"TrnLog" style:UIBarButtonItemStylePlain target:self action:@selector(handleDisplayTrnLog)];
    UIBarButtonItem *tmp2 = [[UIBarButtonItem alloc] initWithTitle:lbl style:UIBarButtonItemStylePlain target:self action:@selector(handleToggleItemsDates)];
      
      self.navigationItem.rightBarButtonItems = @[tmp1,tmp2]; // inserts right to left
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSDate *today = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEE, MM/dd/yyyy"];
    self.title = [df stringFromDate:today];
    
    if (refreshDueToEdit)
    {
        refreshDueToEdit = NO;
        [self loadOrReloadCurrentItemView:YES];
    }
    else
    {
        // ** (lifecycle) event order/trigger on initial will appear
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
            editingNodeID = [[aRecord objectAtIndex:0] integerValue];
            
            EditItem *tmp = [[EditItem alloc] initForNodeID:editingNodeID withCurrentSnapID:currSnapID];
            // *** (6)
            tmp.delegate = self;
            [[self navigationController] pushViewController:tmp animated:YES];
        }
    }
}

// *** (7)
-(void) doPassbackEditItem: (BOOL) wasCancelled originalContentGlob: (NSString *) theoriginalContentGlob newContentGlob: (NSString *) theNewContentGlob
{
   
    // ** we are doing trnlog here to avoid having to instance an a second copy of trnlogger in the edit module, this needs to be redone in the edit module anyway to properly respect incomplete operations, but then the local trnlogger will have wrong maxid
    //
    if (!wasCancelled)
    {
        [db openDB];
        NSString *changeData;
        changeData = theoriginalContentGlob;
        changeData = [changeData stringByAppendingString:@":"];
        changeData = [changeData stringByAppendingString:theNewContentGlob];
        [trnLogger logStartEditTransactionOfNodeID:editingNodeID withChangeData:changeData];
        [trnLogger logEndTransaction];
        [db closeDB];
    }
    
    refreshDueToEdit = !wasCancelled;
    [self.navigationController popViewControllerAnimated:NO];
}

-(void) loadOrReloadCurrentItemView:(BOOL) forceReload
{
    NSString *sql;
    NSMutableArray *localRecords;
    
    [db openDB];
    sql = @"SELECT NodeID,ChildCount,ItemText,isGrayedOut,Notes,BumpCtr,BumpToTopDate,DateOfEvent FROM Items WHERE (SnapID = ";
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    if (displayMode == 3)
    {
        sql = [sql stringByAppendingString:@") AND (isDeleted = 0) AND ((DateOfEvent IS NOT NULL) OR (BumpToTopDate IS NOT NULL)) ORDER BY COALESCE(DateOfEvent,BumpToTopDate)"];
    }
    else
    {
        sql = [sql stringByAppendingString:@") AND (ParentNodeID = "];
           sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currParentNodeID]];
           sql = [sql stringByAppendingString:@") AND (isDeleted = 0)"];
    }
   
    // * have to use variable local to this scope then copy to instance variable
    [db doSelect:sql records:&localRecords];
    [db closeDB];
    // ***** resort the table based on combo of BumpCtr,BumpToTopDate,DateOfEvent if not DateReview mode
    if (displayMode != 3)
    {
        viewRecords = [self sortTheRecords:&localRecords];
    }
    else
    {
        viewRecords = [localRecords mutableCopy];
    }
    
    if (forceReload)
    {
        [self.tableView reloadData];
    }
}

-(NSMutableArray *) sortTheRecords: (NSMutableArray *_Nullable*_Nullable) recordList
{
    NSArray *aRecord;
    NSMutableArray *sortData;
    NSUInteger idx,lastNdx;
    NSInteger maxBumpCtr;
    NSInteger thisBumpCtr;
    NSInteger netPriority;
    NSInteger daysUntilDate;
    NSString *aField;
    NSArray *sortRecord;
    NSInteger thisNodeID;
    
    sortData = [[NSMutableArray alloc] init];
    // 1.2 fix for the abuse of zero records = -1
    if ([*recordList count] == 0)
    {
        return [*recordList copy];
    }
    lastNdx = [*recordList count] - 1;
    // first get maximum bumpctr
    maxBumpCtr = 0;
    for (idx = 0; idx <= lastNdx; idx++)
    {
        aRecord = [*recordList objectAtIndex:idx];
        // 5 BumpCtr
        // 6 BumpToTopDate
        // 7 DateOfEvent
        thisBumpCtr = [[aRecord objectAtIndex:5] integerValue];
        if (thisBumpCtr > maxBumpCtr)
        {
            maxBumpCtr = thisBumpCtr;
        }
    }
    // now determine net priority of each item
    for (idx = 0; idx <= lastNdx; idx++)
       {
           aRecord = [*recordList objectAtIndex:idx];
           // 0 NodeID
           // 5 BumpCtr
           // 6 BumpToTopDate
           // 7 DateOfEvent
           thisNodeID = [[aRecord objectAtIndex:0] integerValue];
           
           netPriority = [[aRecord objectAtIndex:5] integerValue];
           aField = [aRecord objectAtIndex:6];
           if (![aField isEqualToString:[db cDBNull]])
           {
               daysUntilDate = [ugbl daysBetweenDate:[ugbl todaysDate] and:[ugbl dateFromSortable:aField]];
               if (daysUntilDate <= 0)
               {
                   netPriority = maxBumpCtr+1;
               }
           }
           aField = [aRecord objectAtIndex:7];
           if (![aField isEqualToString:[db cDBNull]])
           {
               daysUntilDate = [ugbl daysBetweenDate:[ugbl todaysDate] and:[ugbl dateFromSortable:aField]];
               if (daysUntilDate <= 0)
               {
                   netPriority = maxBumpCtr+2;
               }
           }
           // recordIndex,netPriority,nodeID;
           sortRecord = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:idx] , [NSNumber numberWithInteger:netPriority],[NSNumber numberWithInteger:thisNodeID],nil];
              [sortData addObject:sortRecord];
       }
    
    // now have to produce a new recordList with items in corrrect order
    //
    NSArray *sortedArray = [sortData sortedArrayUsingComparator:^NSComparisonResult(NSArray *p1,NSArray *p2){
        
        NSInteger p1Value;
        NSInteger p2Value;
        
        // recordIndex,netPriority,nodeID;
        
        p1Value = [(NSNumber *)[p1 objectAtIndex:1] intValue];
        p2Value = [(NSNumber *)[p2 objectAtIndex:1] intValue];
        // higher values come before lower values so we invert the return values
        // within equal, make the decision based on the node id
        if (p1Value < p2Value)
        {
            return NSOrderedDescending;
        }
        else if (p1Value > p2Value)
        {
            return NSOrderedAscending;
        }
        else
        {
            //return NSOrderedSame;
            p1Value = [(NSNumber *)[p1 objectAtIndex:2] intValue];
            p2Value = [(NSNumber *)[p2 objectAtIndex:2] intValue];
            if (p1Value < p2Value)
            {
                return NSOrderedAscending;
            }
            else
            {
                 return NSOrderedDescending;
            }
        }
    }];
    
    // now reconstruct recordList in correct order
    NSMutableArray *newRecordlist = [[NSMutableArray alloc] init];
    NSInteger thisRecordNdx;
    
     for (idx = 0; idx <= lastNdx; idx++)
     {
         thisRecordNdx = [(NSNumber *)[[sortedArray objectAtIndex:idx] objectAtIndex:0] intValue];
         [newRecordlist addObject:[*recordList objectAtIndex:thisRecordNdx]];
     }
    
    return [newRecordlist copy];
}
-(void)handleDisplayTrnLog

{
    if (displayMode == 2)
    {
        return;
    }
    TrnLogManagerTableViewController *tmp = [[TrnLogManagerTableViewController alloc] initForViewWithCurrSnapID:currSnapID];
    [[self navigationController] pushViewController:tmp animated:YES];
}

-(void)handleToggleItemsDates
{
    if (displayMode == 2)
    {
        return;
    }
    if (displayMode == 3)
    {
        displayMode = 1;
        searchOrAdd.enabled = YES;
    }
    else
    {
        displayMode = 3;
        searchOrAdd.enabled = NO;
    }
    
    [self setTopButtons];
    [self loadOrReloadCurrentItemView:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tmpRecord;
    NSInteger childCount;
    
    NSUInteger row;
    row = [indexPath row];
    
    // top row allows go to root, if not at root now
    // ** disallow if in search mode?
    
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
    
    if (displayMode == 1)
    {
        aBump = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Bump" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
            NSInteger nodeID;
            NSArray *aRecord;
            NSString *sql;
            
            aRecord = [self->viewRecords objectAtIndex:(row-1)];
           
            nodeID = [(NSString *)[aRecord objectAtIndex:0] integerValue];
            
            [self->trnLogger logStartBumpTransactionOfNodeID:nodeID];
            [self->db openDB];

            sql = @"UPDATE Items SET BumpCtr = BumpCtr + 1";
            sql = [sql stringByAppendingString:@" WHERE (SnapID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
            sql = [sql stringByAppendingString:@") AND (NodeID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)nodeID]];
            sql = [sql stringByAppendingString:@")"];
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
                sql = [sql stringByAppendingString:@")"];
                [self->db executeSQLCommand:sql];
                
                if (self->currParentNodeID != 0)
                {
                    sql = @"UPDATE Items SET ChildCount = ChildCount - 1 WHERE (SnapID = ";
                    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
                    sql = [sql stringByAppendingString:@") AND (NodeID = "];
                    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currParentNodeID)]];
                    sql = [sql stringByAppendingString:@")"];
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
           
            nodeID = [(NSString *)[aRecord objectAtIndex:0] integerValue];
            
            [self->trnLogger  logStartGrayToggleTransactionOfNodeID:nodeID newStateIsGray:(1-[(NSString *)[aRecord objectAtIndex:3] integerValue] == 1)];
            [self->db openDB];
            
            sql = @"UPDATE Items SET isGrayedOut = 1 - isGrayedOut ";
            sql = [sql stringByAppendingString:@" WHERE (SnapID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
            sql = [sql stringByAppendingString:@") AND (NodeID = "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)nodeID]];
            sql = [sql stringByAppendingString:@")"];
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

    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MainListCell"];
    
    // * needed for background image to show through cells
    cell.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.text = @"";
    
    NSUInteger row;
    row = [indexPath row];
    if (row == 0)
    {
        NSString *lbl;
        lbl = @"";
        if (currParentNodeID != 0)
        {
            lbl = [lbl stringByAppendingString:@"<-"];
        }
        lbl = [lbl stringByAppendingString:@"("];
        lbl = [lbl stringByAppendingString:currParentNodeText];
        lbl = [lbl stringByAppendingString:@")"];
        
        
        cell.textLabel.text = lbl;
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
        // annotations
        NSString *annotations;
        annotations = @"";
        if (![[aRecord objectAtIndex:4] isEqualToString:[db cDBNull]])
        {
            annotations = [annotations stringByAppendingString:@"Notes"];
        }
        NSInteger bumpctr;
        bumpctr = [[aRecord objectAtIndex:5] integerValue];
        if (bumpctr > 0)
        {
            if ([annotations length] != 0)
            {
                annotations = [annotations stringByAppendingString:@","];
                
            }
             annotations = [annotations stringByAppendingString:[@"Bump " stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)bumpctr]]];
        }
        // 6 BumpToTopDate, 7 DateOfEvent
        
        NSString *aDate;
    
        aDate = [aRecord objectAtIndex:6];
        if (![aDate isEqualToString:[db cDBNull]])
        {
            if ([annotations length] != 0)
                       {
                           annotations = [annotations stringByAppendingString:@","];
                           
                       }
                        annotations = [annotations stringByAppendingString:[@"BumpToTop " stringByAppendingString:[ugbl dateSortableToAugmentedHuman:aDate]]];
            // * earlier date must be first
            // [u todaysDate]
            // [u dateFromSortable:aDate ]
            //
            annotations = [annotations stringByAppendingString:@" ("];
            annotations = [annotations stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)[ugbl daysBetweenDate:[ugbl todaysDate] and: [ugbl dateFromSortable:aDate]]]];
             annotations = [annotations stringByAppendingString:@"d)"];
        }
        aDate = [aRecord objectAtIndex:7];
               if (![aDate isEqualToString:[db cDBNull]])
               {
                   if ([annotations length] != 0)
                              {
                                  annotations = [annotations stringByAppendingString:@","];
                                  
                              }
                               annotations = [annotations stringByAppendingString:[@"DateOfEvent " stringByAppendingString:[ugbl dateSortableToAugmentedHuman:aDate]]];
                   annotations = [annotations stringByAppendingString:@" ("];
                              annotations = [annotations stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)[ugbl daysBetweenDate:[ugbl todaysDate] and: [ugbl dateFromSortable:aDate]]]];
                               annotations = [annotations stringByAppendingString:@"d)"];
                   
               }
        
        cell.detailTextLabel.text = annotations;
    }
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
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
            case 3:
            {
                // we are in search mode or Calendar mode
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
                // so element 0 is now "this node is parent"
                
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
                for (idx = startIdx; idx>=0; idx--)
                {
                    [levelStack addObject:[reverseStack objectAtIndex:idx]];
                }
                NSArray *tmp2;
                tmp2 = [reverseStack objectAtIndex:0];
                
                currParentNodeID = [(NSNumber *)[tmp2 objectAtIndex:0] intValue];
                currParentNodeText = [tmp2 objectAtIndex:1];
               
                displayMode = 1;
                [self setTopButtons];
                
                
                [self loadOrReloadCurrentItemView:YES];
                
                break;
            }
            default:
               
            {
                break;
            }
        }
    }
    searchOrAdd.text = @"";
    // ** trick per internet to make the keyboard go away if it's up
    searchOrAdd.enabled = NO;
    searchOrAdd.enabled = YES;
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
        
        sql = @"SELECT NodeID,ChildCount,ItemText,isGrayedOut,Notes,BumpCtr,BumpToTopDate,DateOfEvent FROM Items WHERE (ItemText LIKE '%";
        sql = [sql stringByAppendingString:tmp];
        sql = [sql stringByAppendingString:@"%') AND (SnapID = "];
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)(self->currSnapID)]];
        sql = [sql stringByAppendingString:@") AND (isDeleted = 0)"];
        sql = [sql stringByAppendingString:@") ORDER BY NodeID"];
        
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
        [textField resignFirstResponder];
        return NO;
    }
    
    
    [trnLogger logStartAddTransactionOfNodeID:(currMaxNodeID+1) parentNodeID:currParentNodeID];
    [db openDB];
    
    // @"CREATE TABLE IF NOT EXISTS Items (SnapID INTEGER NOT NULL, NodeID INTEGER NOT NULL, ParentNodeID INTEGER NOT NULL, ChildCount INTEGER NOT NULL, ItemText TEXT NOT NULL, Notes TEXT, BumpCtr INTEGER NOT NULL, BumpToTopDate TEXT, DateOfEvent TEXT, isGrayedOut INTEGER NOT NULL, isDeleted INTEGER NOT NULL, PRIMARY KEY (SnapID, NodeID))"
    // ** V1.7 have to put in field names explictly because field order may differ
    // **    in a newly created DB vs a upgraded database
    [db doCommandWithParamsStart:@"INSERT INTO Items (SnapID,NodeID,ParentNodeID,ChildCount,ItemText,Notes,BumpCtr,BumpToTopDate,isGrayedOut,isDeleted,DateOfEvent) VALUES (?,?,?,0,?,NULL,0,NULL,0,0,NULL)"];
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
        sql = [sql stringByAppendingString:@")"];
        [db executeSQLCommand:sql];
    }
    
    [db closeDB];
    [trnLogger logEndTransaction];
    
    textField.text = @"";
    [textField resignFirstResponder];
    // ** (lifecycle) apparently list refreshes without need to force it?
    displayMode = 1;
    [self setTopButtons];
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
