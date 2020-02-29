//
//  EditItem.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/23/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//
// ** new release ... how to "force" upgrading code to run

#import "EditItem.h"
// ** how is Interface used in .m?
@interface EditItem ()

@end

@implementation EditItem
// ** check for db isolation everywhere used
-(id) initForNodeID: (NSInteger) nodeID withCurrentSnapID: (NSInteger) snapID
{
    if (self = [super init])
    {
        db = [[DBWrapper alloc] initForDbFile:@"ToDoDb"];
        ugbl = [[Utility alloc] init];
        ourNodeID = nodeID;
        currSnapID = snapID;
        
        return self;
    }
    else
    {
        return nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // load the database record here, appear might happen multiple times if we push textview/datepicker controllers
    // editable fields: ItemText, Notes, BumpCtr, BumpToTopDate
    NSString *sql;
    NSMutableArray *localRecords;
    NSMutableArray *theDBRecord;
    
    [db openDB];
    sql = @"SELECT ItemText,Notes,BumpCtr,BumpToTopDate,DateOfEvent FROM Items WHERE (SnapID = ";
    // ** efficiency of NSString vs NSMutableString
    
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") AND (NodeID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)ourNodeID]];
    sql = [sql stringByAppendingString:@");"];
    [db doSelect:sql records:&localRecords];
    [db closeDB];
    theDBRecord = [[localRecords objectAtIndex:0] mutableCopy];
    _txtItemText.text = [theDBRecord objectAtIndex:0];
    
    _txtviewNotes.text = [db dbNullToEmptyString:[theDBRecord objectAtIndex:1]];
    _txtviewNotes.backgroundColor = [UIColor lightGrayColor];
    _txtBumpCtr.text = [NSString stringWithFormat:@"%ld", (long)[[theDBRecord objectAtIndex:2] integerValue]];
    _txtBumpToTopDate.text = [ugbl dateSortableToHuman:[db dbNullToEmptyString:[theDBRecord objectAtIndex:3]]];
    _txtDateOfEvent.text = [ugbl dateSortableToHuman:[db dbNullToEmptyString:[theDBRecord objectAtIndex:4]]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnEditNotesPressed:(id)sender {
    TextViewEditor *tmp = [[TextViewEditor alloc] initWithText:_txtviewNotes.text  withItemShortDescription:@"Item Notes"];
               
                tmp.delegate = self;
    [[self navigationController] pushViewController:tmp animated:YES];
}

-(void) doPassbackTextViewEditor: (NSString *) theText cancelWasTapped: (BOOL) wasCancelled
{
    // ** (lifecycle) refresh view needed?
    if (!wasCancelled)
    {
        _txtviewNotes.text = [theText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)btnBumpCtrIncreasePressed:(id)sender {
    NSString *tmp;
    NSInteger tmpi;
    
    tmp = [_txtBumpCtr.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([tmp isEqualToString:@""])
    {
        tmp = @"0";
    }
    if (![ugbl doesContainValidNonNegativeInteger:tmp])
    {
        [ugbl displayPopUpAlert:@"Error" withMessage:@"Bump Counter must be an integer >=0"];
    }
    else
    {
        tmpi = [tmp integerValue];
        tmpi += 1;
        _txtBumpCtr.text = [NSString stringWithFormat:@"%ld", (long)tmpi];
    }
}

- (IBAction)btnBumpCtrDecreasePressed:(id)sender {
    NSString *tmp;
    NSInteger tmpi;
    
    tmp = [_txtBumpCtr.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([tmp isEqualToString:@""])
    {
        tmp = @"0";
    }
    if (![ugbl doesContainValidNonNegativeInteger:tmp])
    {
        [ugbl displayPopUpAlert:@"Error" withMessage:@"Bump Counter must be an integer >=0"];
    }
    else
    {
        tmpi = [tmp integerValue];
        if (tmpi == 0)
        {
            [ugbl displayPopUpAlert:@"Error" withMessage:@"Bump Counter cannot be negative"];
        }
        else
        {
            tmpi -= 1;
        }
        _txtBumpCtr.text = [NSString stringWithFormat:@"%ld", (long)tmpi];
        
    }
}
- (IBAction)btnOKPressed:(id)sender {
   // do the db update here
    
    NSString *newItemText;
    NSString *newNotes;
    NSString *newBumpCtr;
    NSString *newBumpToTopDate;
    NSString *newDateOfEvent;
    NSString *tmp;
    
    tmp = [_txtItemText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([tmp isEqualToString:@""])
    {
        [ugbl displayPopUpAlert:@"Error" withMessage:@"Item Text cannot be an empty string"];
        return;
    }
    newItemText = tmp;
    
    newNotes = [_txtviewNotes.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    tmp = [_txtBumpCtr.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    if ([tmp isEqualToString:@""])
    {
        tmp = @"0";
    }
    if (![ugbl doesContainValidNonNegativeInteger:tmp])
    {
        [ugbl displayPopUpAlert:@"Error" withMessage:@"Bump Counter must be an integer >=0"];
        return;
    }
    newBumpCtr = tmp;
    
    tmp = [_txtBumpToTopDate.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    if (![tmp isEqualToString:@""])
    {
        if (![ugbl doesContainValidHumanDate:tmp])
        {
            [ugbl displayPopUpAlert:@"Error" withMessage:@"Bump To Top Date must be a valid date"];
            return;
        }
    }
    newBumpToTopDate = [ugbl dateHumanToSortable:tmp];
    
    tmp = [_txtDateOfEvent.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
       if (![tmp isEqualToString:@""])
       {
           if (![ugbl doesContainValidHumanDate:tmp])
           {
               [ugbl displayPopUpAlert:@"Error" withMessage:@"DateOfEvent Date must be a valid date"];
               return;
           }
       }
    
    newDateOfEvent = [ugbl dateHumanToSortable:tmp];
    
    // ** all param reads/writes nullable handling
    // ** nullable yes or no on records return
    
    [db openDB];
    [db doCommandWithParamsStart:@"UPDATE Items SET ItemText = ?,Notes = ?,BumpCtr = ?,BumpToTopDate=?,DateOfEvent=? WHERE (SnapID = ?) AND (NodeID = ?);"];
    [db doCommandWithParamsAddParameterOfType:@"S" paramValue:newItemText];
    [db doCommandWithParamsAddParameterOfType:@"NS" paramValue:newNotes];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:newBumpCtr];
    [db doCommandWithParamsAddParameterOfType:@"NS" paramValue:newBumpToTopDate];
     [db doCommandWithParamsAddParameterOfType:@"NS" paramValue:newDateOfEvent];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    [db doCommandWithParamsAddParameterOfType:@"I" paramValue:[NSString stringWithFormat:@"%ld", (long)ourNodeID]];
    [db doCommandWithParamsEnd];
    [db closeDB];
    
    // *** (3)
    [self.delegate doPassbackEditItem: NO];
}


- (IBAction)btnCancelPressed:(id)sender {
     [self.delegate doPassbackEditItem: YES];
}


@end
