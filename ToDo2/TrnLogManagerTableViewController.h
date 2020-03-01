//
//  TrnLogManagerTableViewController.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/22/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBWrapper.h"
NS_ASSUME_NONNULL_BEGIN

@interface TrnLogManagerTableViewController : UITableViewController
{
    DBWrapper *db;
    NSMutableArray *viewRecords;
    NSInteger currSnapID;
    NSInteger currMaxTrnLogSeqNum;
}

-(id) initForViewWithCurrSnapID: (NSInteger) snapID;
-(id) initForUtilityWithCurrSnapID: (NSInteger) snapID;

-(void) logStartAddTransactionOfNodeID : (NSInteger) newNodeID parentNodeID: (NSInteger) theParentNodeID;
-(void) logStartDeleteTransactionOfNodeID : (NSInteger) nodeID;
-(void) logStartBumpTransactionOfNodeID : (NSInteger) nodeID;
-(void) logStartGrayToggleTransactionOfNodeID : (NSInteger) nodeID newStateIsGray: (BOOL) theNewStateIsGray;
-(void) logStartEditTransactionOfNodeID : (NSInteger) nodeID withChangeData : (NSString *) theChangeData;
-(void) logEndTransaction;

@end

NS_ASSUME_NONNULL_END
