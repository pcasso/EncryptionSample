//
//  PCEncryptionFileManager
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PCEncryptionFileManager : NSObject

/**
 *  Returns file path name for a file name
 *
 *  @param fileName - name of the file
 *
 *  @return absolute file pathe name
 */
+ (NSString *)encryptedPathForFileName:(NSString *)fileName;

/**
 *  Encrypt data
 *
 *  @param data     input data
 *  @param fileName file name to be saved
 *  @param error    error object
 *
 *  @return true/false ,if data was encrypted
 */
+ (BOOL)encryptData:(NSData *)data
           fileName:(NSString *)fileName
              error:(NSError **)error;

/**
 *  Encrypt data
 *
 *  @param data     input data
 *  @param pincode  user pin code
 *  @param fileName file name to be saved
 *  @param error    error object
 *
 *  @return true/false ,if data was encrypted
 */
+ (BOOL)encryptData:(NSData *)data
       withPinCode:(NSString *)pincode
           fileName:(NSString *)fileName
              error:(NSError **)error;


/**
 *  Decrypt data
 *
 *  @param fileName file name to be decrypted
 *  @param error    error object
 *
 *  @return encrypted data
 */
+ (NSData *)decryptDataForFileName:(NSString *)fileName
                             error:(NSError **)error;

/**
 *  Decrypt data
 *
 *  @param pincode  pincode
 *  @param fileName file name to be decrypted
 *  @param error    error object
 *
 *  @return encrypted data
 */
+ (NSData *)decryptDataWithPinCode:(NSString *)pincode
                           fileName:(NSString *)fileName
                              error:(NSError **)error;

/**
 *  Delete all files
 *
 *  @return if files were deleted or not
 */
+ (BOOL)deleteAllEncryptedFiles;



/**
 *  Save dictionray to file
 *
 *  @param dictionary input dictionary
 *  @param fileName   name of the file
 *
 *  @return true/false, file was saved
 */
+ (BOOL)saveInformation:(NSDictionary *) dictionary toFile:(NSString*)fileName ;


/**
 *  Decrypt stored file
 *
 *  @param fileName name of the file
 *  @param error    error object passed
 *
 *  @return file attributes as dictionary
 */
+ (NSDictionary *)decryptFile:(NSString*)fileName withError:(NSError **)error ;

@end
