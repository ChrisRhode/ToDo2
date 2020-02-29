//
//  EditItem.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/23/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBWrapper.h"
#import "Utility.h"
#import "TextViewEditor.h"

// ** look up NS_ASSUME_NONNULL_BEGIN
// ** can we manage currSnapID as a global better somehow?
NS_ASSUME_NONNULL_BEGIN

// *** (1) protocol definition (required/optional)
@protocol EditItemPassbackDelegate <NSObject>

-(void) doPassbackEditItem: (BOOL) wasCancelled;

@end

@interface EditItem : UIViewController<TextViewEditorPassbackDelegate>
{
    NSInteger ourNodeID;
    NSInteger currSnapID;
    DBWrapper *db;
    Utility *ugbl;
}

// *** (2)
@property (nonatomic,weak) id <EditItemPassbackDelegate> delegate;
// *** (2.5) any properties for pushing in or out values etc
// ** proper attributes for all properties ... understand copy
//
@property (weak, nonatomic) IBOutlet UITextField *txtItemText;
@property (weak, nonatomic) IBOutlet UITextView *txtviewNotes;
@property (weak, nonatomic) IBOutlet UITextField *txtBumpCtr;
@property (weak, nonatomic) IBOutlet UITextField *txtBumpToTopDate;
@property (weak, nonatomic) IBOutlet UITextField *txtDateOfEvent;

- (IBAction)btnOKPressed:(id)sender;
- (IBAction)btnCancelPressed:(id)sender;
- (IBAction)btnEditNotesPressed:(id)sender;
- (IBAction)btnBumpCtrIncreasePressed:(id)sender;
- (IBAction)btnBumpCtrDecreasePressed:(id)sender;
// ** implement date picker (spinners / calendar view)
-(id) initForNodeID: (NSInteger) nodeID withCurrentSnapID: (NSInteger) snapID;

@end

NS_ASSUME_NONNULL_END
