//
//  MainListTableViewController.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utility.h"
#import "DBWrapper.h"
// *** (4)
#import "EditItem.h"
#import "TrnLogManagerTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

// *** (5)
@interface MainListTableViewController : UITableViewController<UITextFieldDelegate,UIGestureRecognizerDelegate,EditItemPassbackDelegate>
{
    DBWrapper *db;
    Utility *ugbl;
    TrnLogManagerTableViewController *trnLogger;
    
    UITextField *searchOrAdd;
    
    NSInteger currParentNodeID;
    NSString *currParentNodeText;
    NSInteger currSnapID;
    NSInteger currMaxNodeID;
    
    NSMutableArray *viewRecords;
   
    NSMutableArray *levelStack;
    NSInteger displayMode;
    NSInteger editingNodeID;
    NSInteger moveParentNodeID;
    BOOL moveMode;
    BOOL refreshDueToEdit;
}

@end

NS_ASSUME_NONNULL_END



