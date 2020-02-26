//
//  TextViewEditor.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/26/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "TextViewEditor.h"

@interface TextViewEditor ()

@end

@implementation TextViewEditor

-(id) initWithText: (NSString *) currentText withItemShortDescription: (NSString *) theDescription
{
    if (self = [super init])
    {
        saveInitialText = currentText;
        saveItemDescription = theDescription;
        
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
    _txtItemDescription.text = saveItemDescription;
    _txtItemDescription.adjustsFontSizeToFitWidth = YES;
    _txtItemText.text = saveInitialText;
    _txtItemText.backgroundColor = [UIColor lightGrayColor];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)handleCancelButtonPressed:(id)sender {
    [self.delegate doPassbackTextViewEditor:@"" cancelWasTapped:YES];
}

- (IBAction)handleOKButtonPressed:(id)sender {
    
    NSString *tmp;
    tmp = _txtItemText.text;
    
    [self.delegate doPassbackTextViewEditor:tmp cancelWasTapped:NO];
}
@end
