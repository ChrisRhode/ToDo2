//
//  DatePicker.h
//  ToDo2
//
//  Created by Christopher Rhode on 3/4/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utility.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DatePickerPassbackDelegate <NSObject>

-(void) doPassbackDatePicker: (NSString *) theHumanDate cancelWasTapped: (BOOL) wasCancelled;

@end

@interface DatePicker : UIViewController
{
    Utility *ugbl;
    NSString *saveDateText;
    NSString *saveItemDescription;
}
@property (nonatomic,weak) id <DatePickerPassbackDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *lblWhatThisIs;
@property (weak, nonatomic) IBOutlet UITextField *txtDate;
- (IBAction)btnToday:(id)sender;
- (IBAction)btnTomorrow:(id)sender;
- (IBAction)btnAdd1d:(id)sender;
- (IBAction)btnAdd7d:(id)sender;
- (IBAction)btnUpcomingMonday:(id)sender;
- (IBAction)btnOK:(id)sender;
- (IBAction)btnCancel:(id)sender;

-(id) initWithHumanDate: (NSString *) currentDate withItemShortDescription: (NSString *) theDescription;
@end

NS_ASSUME_NONNULL_END
