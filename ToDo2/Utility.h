//
//  Utility.h
//  ToDo2
//
//  Created by Christopher Rhode on 2/19/20.
//  Copyright © 2020 Christopher Rhode. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utility : NSObject

-(NSString *) getDocumentsDirectory;
-(NSDate *) dateHumanDateToDate: (NSString *) theDate;
-(NSString *) dateToHumanDate: (NSDate *) theDate;
-(BOOL) doesContainValidAugmentedHumanDate: (NSString *) theString;
-(NSDate *) dateAugmentedHumanDateToDate: (NSString *) theDate;
-(NSString *) dateToAugmentedHumanDate: (NSDate *) theDate;
-(NSString *) dateHumanToSortable: (NSString *) sourceDate;
-(NSString *) dateSortableToHuman: (NSString *) sourceDate;
-(NSString *) dateSortableToAugmentedHuman: (NSString *) sourceDate;
-(BOOL) doesContainValidNonNegativeInteger: (NSString *) theString;
-(BOOL) doesContainValidHumanDate: (NSString *) theString;
-(void) displayPopUpAlert: (NSString *) theTitle withMessage: (NSString *) theMessage;
-(NSDate *) dateFromSortable: (NSString *) theSortableDate;
-(NSDate *) todaysDate;
-(NSInteger) daysBetweenDate: (NSDate *) firstDate and: (NSDate *) secondDate;
-(NSString *) encodeString: (NSString *) theString toAvoidCharacters: (NSString *) charList;
-(NSString *) decodeString: (NSString *) theString;

@end

NS_ASSUME_NONNULL_END
