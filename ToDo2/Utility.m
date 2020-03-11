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
   
    NSString *tmp;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    tmp = [[paths objectAtIndex:0] stringByAppendingString:@"/"];
    
    return tmp;
    
}
-(NSDate *) dateHumanDateToDate: (NSString *) theDate
{
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
       [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *d = [df dateFromString:theDate];
    return d;
}

-(NSString *) dateToHumanDate: (NSDate *) theDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    return [df stringFromDate:theDate];
    
}

-(BOOL) doesContainValidAugmentedHumanDate: (NSString *) theString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
   
    [df setDateFormat:@"EEEEEE MM/dd/yyyy"];
    NSDate *d = [df dateFromString:theString];
    return (d != nil);
}

-(NSDate *) dateAugmentedHumanDateToDate: (NSString *) theDate
{
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
       [df setDateFormat:@"EEEEEE MM/dd/yyyy"];
    NSDate *d = [df dateFromString:theDate];
    return d;
}

-(NSString *) dateToAugmentedHumanDate: (NSDate *) theDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEEEEE MM/dd/yyyy"];
    return [df stringFromDate:theDate];
    
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

-(NSString *) dateSortableToAugmentedHuman: (NSString *) sourceDate;
{
    NSString *tmp = [self dateSortableToHuman:sourceDate];
    if ([tmp isEqualToString:@""])
    {
        return @"";
    }
    NSDate *d = [self dateHumanDateToDate:tmp];
    return [self dateToAugmentedHumanDate:d];
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
  
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *d = [df dateFromString:theString];
    return (d != nil);
}

-(void) displayPopUpAlert: (NSString *) theTitle withMessage: (NSString *) theMessage

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

-(NSDate *) dateFromSortable: (NSString *) theSortableDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    return [df dateFromString:theSortableDate];
}

-(NSDate *) todaysDate
{
    NSDate *tmp;
    tmp = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];
    return tmp;
    
}
-(NSInteger) daysBetweenDate: (NSDate *) firstDate and: (NSDate *) secondDate
{
    NSDateComponents *c;
    c = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:firstDate toDate:secondDate options:0];
    return [c day];
}

-(NSString *) encodeString: (NSString *) theString toAvoidCharacters: (NSString *) charList
{
    NSString *newString;
    NSString *aChar;
    NSUInteger idx,lastNdx;
    NSRange r;
    NSCharacterSet *cs;
    
    cs = [NSCharacterSet characterSetWithCharactersInString:[charList stringByAppendingString:@"%"]];
    
    newString = @"";
 
    if ([theString isEqualToString:@""])
    {
        return @"";
    }
    lastNdx = [theString length] - 1;
    r.length = 1;
    for (idx = 0; idx <= lastNdx; idx++)
    {
        r.location = idx;
        aChar = [theString substringWithRange:r];
        //return ([theString rangeOfCharacterFromSet:notdigits].location == NSNotFound);
        if ([aChar rangeOfCharacterFromSet:cs].location != NSNotFound)
        {
            unichar chr = [aChar characterAtIndex:0];
            newString = [newString stringByAppendingString:@"%"];
            newString = [newString stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)chr]];
            newString = [newString stringByAppendingString:@"%"];
        }
        else
        {
            newString = [newString stringByAppendingString:aChar];
        }
    }
    
    return newString;
    
}

-(NSString *) decodeString: (NSString *) theString
{
    NSString *newString;
    NSString *aChar;
    NSUInteger idx,lastNdx;
    NSRange r;
    NSRange find;
    NSRange nextFind;
    NSRange selection;
    
    newString = @"";
    if ([theString isEqualToString:@""])
       {
           return @"";
       }
    
    lastNdx = [theString length] - 1;
    r.length = 1;
    idx = 0;
    while (idx <=lastNdx)
    {
        r.location = idx;
        aChar = [theString substringWithRange:r];
        if ([aChar isEqualToString:@"%"])
        {
            nextFind.location = idx+1;
            // AB%nnn%C
            // 01234567
            nextFind.length = lastNdx - idx;
            find = [theString rangeOfString:@"%" options:NSLiteralSearch range:nextFind];
            // chars from (idx+1 to find.location-1 inclusive
            selection.location = (idx+1);
            selection.length = (find.location-1)-(idx+1)+1;
            unichar chr = [[theString substringWithRange:selection] integerValue];
            newString = [newString stringByAppendingString:[NSString stringWithFormat:@"%c", chr]];
            idx = idx + selection.length+2;
        }
        else
        {
            newString = [newString stringByAppendingString:aChar];
            idx +=1;
        }
        
    }
    
    return newString;
}
@end
