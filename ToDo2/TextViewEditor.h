//
//  TextViewEditor.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/26/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TextViewEditorPassbackDelegate <NSObject>

-(void) doPassbackTextViewEditor: (NSString *) theText cancelWasTapped: (BOOL) wasCancelled;

@end

@interface TextViewEditor : UIViewController
{
    NSString *saveInitialText;
    NSString *saveItemDescription;
}
@property (nonatomic,weak) id <TextViewEditorPassbackDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *txtItemDescription;
@property (weak, nonatomic) IBOutlet UITextView *txtItemText;

-(id) initWithText: (NSString *) currentText withItemShortDescription: (NSString *) theDescription;

- (IBAction)handleCancelButtonPressed:(id)sender;
- (IBAction)handleOKButtonPressed:(id)sender;

@end

NS_ASSUME_NONNULL_END
