//
//  DBMgr.h
//  ToDo2
//
//  Created by Christopher Rhode on 4/21/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBWrapper.h"
#import "Utility.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBMgr : UIViewController
{
    DBWrapper *db;
    Utility *ugbl;
    NSInteger currSnapID;
    NSMutableArray *seen;
    NSInteger seenCount;
}

@property (weak, nonatomic) IBOutlet UITextView *txtviewOutput;

-(id) initWithCurrSnapID: (NSInteger) snapID;

@end


NS_ASSUME_NONNULL_END
