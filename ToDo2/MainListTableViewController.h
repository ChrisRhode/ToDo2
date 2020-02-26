//
//  MainListTableViewController.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBWrapper.h"
// *** (4)
#import "EditItem.h"
#import "TrnLogManagerTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

// *** (5)
@interface MainListTableViewController : UITableViewController<UITextFieldDelegate,UIGestureRecognizerDelegate,EditItemPassbackDelegate>
{
    DBWrapper *db;
    TrnLogManagerTableViewController *trnLogger;
    
    UITextField *searchOrAdd;
    
    NSInteger currParentNodeID;
    NSString *currParentNodeText;
    NSInteger currSnapID;
    NSInteger currMaxNodeID;
    
    NSMutableArray *viewRecords;
   
    NSMutableArray *levelStack;
    NSInteger displayMode;
    BOOL refreshDueToEdit;
}

@end

NS_ASSUME_NONNULL_END

// ** everything really wants us to use the successor to UISearchBar
// (1) add xxxDelegate to interface spec in <> in .h
// (2) add pointer to class as instance variable in .h
// (3) alloc init class in load, and set delegate to self (init vs initwithframe?) in .m
//       -- additional calls to class to set up / make visible etc. ... initwithframe...
//    self.view.bounds?  attached to tableview vs tableviewcontroller
//    [self tableView] if the class is itself the tableView
// ((4)) in class itself define the protocol callback(s)
// (5) code any/all protocol callbacks in calling code .m

