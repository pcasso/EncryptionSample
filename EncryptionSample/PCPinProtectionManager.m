//
//  PCPinProtectionManager.m
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import "PCPinProtectionManager.h"
#import "PCEncryptionFileManager.h"

@implementation PCPinProtectionManager


#define kPinProtectionLength 4
NSString * const kIncorrectPinCount     = @"IncorrectPinCount";
NSString * const kPinProtectionFileName = @"Pinprotection";

#pragma -
#pragma mark Random String function
//Generates random string of specified length
+(NSString *) generateRandomStringWithLength: (NSInteger) length {
   
    //1. Prepare letters list
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    //2. Generate random array of specified length
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    //3. Prepare a random string
    for (NSInteger i=0; i<length; i++) {
    
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    
    //4. Return string
    return randomString;
}

#pragma -
#pragma mark Private functions
+(BOOL)hasPinCode{
    
    //1. Generate file name path
    NSString *readPath = [PCEncryptionFileManager encryptedPathForFileName:kPinProtectionFileName];
    
    //2. Check from file manager if the file exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:readPath])
    {
        //3. Return pin code exist
        return YES;
    }
    
    //4. Default No
    return NO;
}

+(BOOL)savePinCode:(NSString*)pinCode
{
    //1. Verify pin length
   
    if (pinCode.length != kPinProtectionLength) {
        
        return NO;
    }
    
    //2. Generate a dictionary of random string
    
    NSString *randomString=[self generateRandomStringWithLength:32];
   
    NSArray *array = @[randomString,];
    
    NSDictionary *dictionary = @{@"ROOT": array};
    
    //3. Archive data for saving
    
    NSData *dictionaryData = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    
    //4. Encrypt dictionary and write it to a file
    
    NSError *error;
    
    if (![PCEncryptionFileManager encryptData:dictionaryData
                        withPinCode:pinCode
                           fileName:kPinProtectionFileName
                              error:&error ]) {
        
        //5. Notify error if obtained
        
        NSLog(@"Could not encrypt data: %@", error);
        return NO;
    }
    
    // 6. Return success
   
    return YES;
}


+(BOOL)isValidPinCode:(NSString*)pinCode
{
    //1. Verify pin length
  
    if (pinCode.length!=kPinProtectionLength) {
        return NO;
    }
    
    
    //2. Decrypt data from pin file name
    NSError *error;
    
    NSData *data = [PCEncryptionFileManager decryptDataWithPinCode:pinCode
                                                fileName:kPinProtectionFileName
                                                   error:&error];
    
    if (data) {
        @try {
            //3. If data , then try to check if data is valid
            NSDictionary *dictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            
            BOOL isValid=dictionary.allKeys.count>0;
           
            if (isValid) {
                
                //4. If valid, reset internal incorrect pin code count to zero
                [self saveIncorrectPinCount:0];
            }
            return isValid;
        }
        @catch (NSException *exception)
        {
            //5. Increase internal incorrect pin code count
            [self incrementIncorrectPinCount];
            //NSLog(@"exception: %@",exception.reason);
            
        }
    }else{
        
        //6. Check for Pin code
        
        if ([self hasPinCode]) {
            
            //7. If pincode is there, then increase internal incorrect pin code count
            [self incrementIncorrectPinCount];
            
            NSLog(@"Error: %@",error.description);
        }
    }
    
    return NO;
}

#pragma -
#pragma mark Counter functions
+(void)incrementIncorrectPinCount{
    
    //1. Fetch current incorrect count
    NSInteger currentIncorrectPinCount=[self incorrectPinCount];
    
    //2. Save new count
    [self saveIncorrectPinCount:++currentIncorrectPinCount];
    
}

+(NSInteger)incorrectPinCount{
   
    //1. Fetch incorrect count
    NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
    
    return [userDefaults integerForKey:kIncorrectPinCount];
}

+(void)saveIncorrectPinCount:(NSInteger)count{
    
    //1. Save incorrect count in user defaults
    
    NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
    
    [userDefaults setInteger:count forKey:kIncorrectPinCount];
    
    [userDefaults synchronize];
}



+(void)resetIncorrectPinCount
{
    //1. Save incorrect count as 0
    [self saveIncorrectPinCount:0];
}
@end
