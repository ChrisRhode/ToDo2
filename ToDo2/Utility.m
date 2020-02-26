//
//  Utility.m
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import "Utility.h"
#import <UIKit/UIKit.h>

@implementation Utility

-(NSString *) getDocumentsDirectory
{
    // **NOTE: Allegedly should use NSURL URLsForDirectory for iOS 8 and greater
    NSString *tmp;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    tmp = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
    
    return tmp;
    
}

// Human: MM/DD/YYYY Sortable: YYYY-MM-DD
-(NSString *) dateHumanToSortable: (NSString *) sourceDate
{
    if ([sourceDate isEqualToString:@""])
    {
        return @"";
    }
    else
    {
        NSString *result;
        NSArray *pieces;
        
        pieces = [sourceDate componentsSeparatedByString:@"/"];
        // ** implicit treatment as string ok?
        result = [NSString stringWithFormat:@"%04ld", (long)[[pieces objectAtIndex:2] integerValue]];
        result = [result stringByAppendingString:@"-"];
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%02ld", (long)[[pieces objectAtIndex:0] integerValue]]];
         result = [result stringByAppendingString:@"-"];
         result = [result stringByAppendingString:[NSString stringWithFormat:@"%02ld", (long)[[pieces objectAtIndex:1] integerValue]]];
        return result;
    }
}
// Human: MM/DD/YYYY Sortable: YYYY-MM-DD
-(NSString *) dateSortableToHuman: (NSString *) sourceDate
{
    if ([sourceDate isEqualToString:@""])
       {
           return @"";
       }
       else
       {
           NSString *result;
           NSArray *pieces;
           
           pieces = [sourceDate componentsSeparatedByString:@"-"];
           // enforce zero filling
          
           result = [NSString stringWithFormat:@"%02ld", (long)[[pieces objectAtIndex:1] integerValue]];
           result = [result stringByAppendingString:@"/"];
           result = [result stringByAppendingString:[NSString stringWithFormat:@"%02ld", (long)[[pieces objectAtIndex:2] integerValue]]];
            result = [result stringByAppendingString:@"/"];
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%04ld", (long)[[pieces objectAtIndex:0] integerValue]]];
           return result;
       }
}

-(BOOL) doesContainValidNonNegativeInteger: (NSString *) theString
{
    // ** there may be better ways to do this
    NSCharacterSet *notdigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    return ([theString rangeOfCharacterFromSet:notdigits].location == NSNotFound);
}

-(BOOL) doesContainValidHumanDate: (NSString *) theString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    // ** will it fail if leading zeroes are missing for MM or DD?
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *d = [df dateFromString:theString];
    return (d != nil);
}

-(void) displayPopUpAlert: (NSString *) theTitle withMessage: (NSString *) theMessage
// ** is this "ok" forcing a UI function in a non UI sublcass
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:theTitle message:theMessage preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [ac dismissViewControllerAnimated:YES completion:nil];
    }];
    [ac addAction:ok];
    // ** per internet yields current navigation controller
    // **  but can break if multiple scenes
    UIViewController *currnc = [UIApplication  sharedApplication].keyWindow.rootViewController;
    [currnc presentViewController:ac animated:YES completion:nil];
}
@end
