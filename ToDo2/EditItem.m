//
//  EditItem.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/23/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//


#import "EditItem.h"

@interface EditItem ()

@end

@implementation EditItem

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
    
    
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)currSnapID]];
    sql = [sql stringByAppendingString:@") AND (NodeID = "];
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)ourNodeID]];
    sql = [sql stringByAppendingString:@")"];
    [db doSelect:sql records:&localRecords];
    [db closeDB];
    
    theDBRecord = [[localRecords objectAtIndex:0] mutableCopy];
    
    _txtItemText.text = [theDBRecord objectAtIndex:0];
    chgDataOld = [ugbl encodeString:[theDBRecord objectAtIndex:0] toAvoidCharacters:@"|:"];
    chgDataOld = [chgDataOld stringByAppendingString:@"|"];
    _txtviewNotes.text = [db dbNullToEmptyString:[theDBRecord objectAtIndex:1]];
    _txtviewNotes.backgroundColor = [UIColor lightGrayColor];
    chgDataOld = [chgDataOld stringByAppendingString:[ugbl encodeString:[db dbNullToEmptyString:[theDBRecord objectAtIndex:1]] toAvoidCharacters:@"|:"]];
    chgDataOld = [chgDataOld stringByAppendingString:@"|"];
    
    _txtBumpCtr.text = [NSString stringWithFormat:@"%ld", (long)[[theDBRecord objectAtIndex:2] integerValue]];
    chgDataOld = [chgDataOld stringByAppendingString:[ugbl encodeString:[NSString stringWithFormat:@"%ld", (long)[[theDBRecord objectAtIndex:2] integerValue]] toAvoidCharacters:@"|:"]];
    chgDataOld = [chgDataOld stringByAppendingString:@"|"];
    
    _txtBumpToTopDate.text = [ugbl dateSortableToHuman:[db dbNullToEmptyString:[theDBRecord objectAtIndex:3]]];
    // * encode dates in change data in Sortable format
    chgDataOld = [chgDataOld stringByAppendingString:[ugbl encodeString:[db dbNullToEmptyString:[theDBRecord objectAtIndex:3]] toAvoidCharacters:@"|:"]];
    chgDataOld = [chgDataOld stringByAppendingString:@"|"];
    
    _txtDateOfEvent.text = [ugbl dateSortableToHuman:[db dbNullToEmptyString:[theDBRecord objectAtIndex:4]]];
    chgDataOld = [chgDataOld stringByAppendingString:[ugbl encodeString:[db dbNullToEmptyString:[theDBRecord objectAtIndex:4]] toAvoidCharacters:@"|:"]];
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

- (IBAction)btnEditDateOfEvent:(id)sender {
    NSString *tmps;
    tmps = [_txtDateOfEvent.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![tmps isEqualToString:@""])
    {
        if (![ugbl doesContainValidHumanDate:tmps])
        {
             [ugbl displayPopUpAlert:@"Error" withMessage:@"DateOfEvent Date must be a valid date"];
            return;
        }
    }
    DatePicker *tmp = [[DatePicker alloc] initWithHumanDate:tmps withItemShortDescription:@"Date of Event"];
    tmp.delegate = self;
    dateBeingEdited = 1;
      [[self navigationController] pushViewController:tmp animated:YES];
    
}

- (IBAction)btnEditBumpToTopDate:(id)sender {
    NSString *tmps;
      tmps = [_txtBumpToTopDate.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      if (![tmps isEqualToString:@""])
      {
          if (![ugbl doesContainValidHumanDate:tmps])
          {
               [ugbl displayPopUpAlert:@"Error" withMessage:@"BumpToTop Date must be a valid date"];
              return;
          }
      }
      DatePicker *tmp = [[DatePicker alloc] initWithHumanDate:tmps withItemShortDescription:@"Bump To Top Date"];
      tmp.delegate = self;
      dateBeingEdited = 2;
        [[self navigationController] pushViewController:tmp animated:YES];
}


-(void) doPassbackDatePicker: (NSString *) theHumanDate cancelWasTapped: (BOOL) wasCancelled
{
    if (!wasCancelled)
    {
        if (dateBeingEdited == 1)
        {
            _txtDateOfEvent.text = theHumanDate;
        }
        else
        {
            _txtBumpToTopDate.text = theHumanDate;
        }
        
    }
     [self.navigationController popViewControllerAnimated:NO];
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
    
    
    
    [db openDB];
    
    // block up new values for trn log
       // ***********
    NSString *chgDataNew;
    
         chgDataNew = [ugbl encodeString:newItemText toAvoidCharacters:@"|:"];
         chgDataNew = [chgDataNew stringByAppendingString:@"|"];
         
         chgDataNew = [chgDataNew stringByAppendingString:[ugbl encodeString:newNotes toAvoidCharacters:@"|:"]];
         chgDataNew = [chgDataNew stringByAppendingString:@"|"];
         
         chgDataNew = [chgDataNew stringByAppendingString:[ugbl encodeString:newBumpCtr toAvoidCharacters:@"|:"]];
         chgDataNew = [chgDataNew stringByAppendingString:@"|"];
         
         chgDataNew = [chgDataNew stringByAppendingString:[ugbl encodeString:newBumpToTopDate toAvoidCharacters:@"|:"]];
         chgDataNew = [chgDataNew stringByAppendingString:@"|"];
         
         chgDataNew = [chgDataNew stringByAppendingString:[ugbl encodeString:newDateOfEvent toAvoidCharacters:@"|:"]];
       
       // ***********
    
    [db doCommandWithParamsStart:@"UPDATE Items SET ItemText = ?,Notes = ?,BumpCtr = ?,BumpToTopDate=?,DateOfEvent=? WHERE (SnapID = ?) AND (NodeID = ?)"];
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
    [self.delegate doPassbackEditItem: NO originalContentGlob:chgDataOld newContentGlob:chgDataNew];
}

- (IBAction)btnCancelPressed:(id)sender {
     [self.delegate doPassbackEditItem: YES originalContentGlob:@"" newContentGlob:@""];
}

@end
