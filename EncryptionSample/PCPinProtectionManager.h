//
//  PCPinProtectionManager.h
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCPinProtectionManager : NSObject

/**
 *  Has Pin Protection on
 *
 *  @return true/false
 */
+(BOOL)hasPinCode;


/**
 *  Entered pin code validity check
 *
 *  @param pinCode - input value
 *
 *  @return true/false
 */
+(BOOL)isValidPinCode:(NSString*)pinCode;


/**
 *  Saves Pin code
 *
 *  @param pinCode -input value
 *
 *  @return true/false, if operation was succesfull or not
 */
+(BOOL)savePinCode:(NSString*)pinCode;


/**
 *  Increase incorrect Pin Count
 */
+(void)incrementIncorrectPinCount;


/**
 *  Incorrect Pin Count
 *
 *  @return curent incorrect pin count
 */
+(NSInteger)incorrectPinCount;

/**
 *  Reset incorrect pin count
 */
+(void)resetIncorrectPinCount;

@end

