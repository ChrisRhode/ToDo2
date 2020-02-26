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
-(NSString *) dateHumanToSortable: (NSString *) sourceDate;
-(NSString *) dateSortableToHuman: (NSString *) sourceDate;
-(BOOL) doesContainValidNonNegativeInteger: (NSString *) theString;
-(BOOL) doesContainValidHumanDate: (NSString *) theString;
-(void) displayPopUpAlert: (NSString *) theTitle withMessage: (NSString *) theMessage;

@end

NS_ASSUME_NONNULL_END
