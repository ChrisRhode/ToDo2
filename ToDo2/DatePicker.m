//
//  DatePicker.m
//  ToDo2
//
//  Created by Christopher Rhode on 3/4/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "DatePicker.h"

@interface DatePicker ()

@end

@implementation DatePicker

-(id) initWithHumanDate: (NSString *) currentDate withItemShortDescription: (NSString *) theDescription
{
    if (self = [super init])
    {
        ugbl = [[Utility alloc] init];
        saveDateText = currentDate;
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
    _txtDate.text = saveDateText;
    _txtDate.clearButtonMode = YES;
    _lblWhatThisIs.text = saveItemDescription;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnToday:(id)sender {
    NSDate *d = [NSDate date];
    _txtDate.text = [ugbl dateToHumanDate:d];
}

- (IBAction)btnTomorrow:(id)sender {
    NSDate *d = [NSDate date];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:1];
    NSDate *d2 = [[NSCalendar currentCalendar] dateByAddingComponents:offset toDate:d options:0];
    _txtDate.text = [ugbl dateToHumanDate:d2];
}

-(NSString *) currentDateValidValue
{
    NSString *tmp;
    tmp = [_txtDate.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([tmp isEqualToString:@""])
    {
        return @"";
    }
    if (![ugbl doesContainValidHumanDate:tmp])
           {
                [ugbl displayPopUpAlert:@"Error" withMessage:@"Date must be a valid date"];
               return @"";
           }
    return tmp;
}
          
- (IBAction)btnAdd1d:(id)sender {
    
    NSString *target = [self currentDateValidValue];
    if ([target isEqualToString:@""])
    {
        return;
    }
  
    NSDate *d = [ugbl dateHumanDateToDate:target];
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:1];
    NSDate *d2 = [[NSCalendar currentCalendar] dateByAddingComponents:offset toDate:d options:0];
    _txtDate.text = [ugbl dateToHumanDate:d2];
}

- (IBAction)btnAdd7d:(id)sender {
    NSString *target = [self currentDateValidValue];
       if ([target isEqualToString:@""])
       {
           return;
       }
        NSDate *d  = [ugbl dateHumanDateToDate:target];
       NSDateComponents *offset = [[NSDateComponents alloc] init];
       [offset setDay:7];
       NSDate *d2 = [[NSCalendar currentCalendar] dateByAddingComponents:offset toDate:d options:0];
       _txtDate.text = [ugbl dateToHumanDate:d2];
}

- (IBAction)btnUpcomingMonday:(id)sender {
    
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:[NSDate date]];
    [dc setDay:(([dc day] + (7- [dc weekday]))+2)];
    NSDate *d2 = [[NSCalendar currentCalendar] dateFromComponents:dc];
    _txtDate.text = [ugbl dateToHumanDate:d2];
}

- (IBAction)btnOK:(id)sender {
    
    NSString *tmp = _txtDate.text;
    
    tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      if (![tmp isEqualToString:@""])
      {
          if (![ugbl doesContainValidHumanDate:tmp])
          {
               [ugbl displayPopUpAlert:@"Error" withMessage:@"Date must be a valid date"];
              return;
          }
      }
      
     [self.delegate doPassbackDatePicker:tmp cancelWasTapped:NO];
}

- (IBAction)btnCancel:(id)sender {
     [self.delegate doPassbackDatePicker:@"" cancelWasTapped:YES];
}
@end
