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
#import "DatePicker.h"

NS_ASSUME_NONNULL_BEGIN

// *** (1) protocol definition (required/optional)
@protocol EditItemPassbackDelegate <NSObject>

-(void) doPassbackEditItem: (BOOL) wasCancelled originalContentGlob: (NSString *) theoriginalContentGlob newContentGlob: (NSString *) theNewContentGlob;

@end

@interface EditItem : UIViewController<TextViewEditorPassbackDelegate,DatePickerPassbackDelegate>
{
    NSInteger ourNodeID;
    NSInteger currSnapID;
    DBWrapper *db;
    Utility *ugbl;
    NSString *chgDataOld;
    NSInteger dateBeingEdited;
}

// *** (2)
@property (nonatomic,weak) id <EditItemPassbackDelegate> delegate;
// *** (2.5) any properties for pushing in or out values etc
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
- (IBAction)btnEditDateOfEvent:(id)sender;

-(id) initForNodeID: (NSInteger) nodeID withCurrentSnapID: (NSInteger) snapID;
- (IBAction)btnEditBumpToTopDate:(id)sender;

@end

NS_ASSUME_NONNULL_END
