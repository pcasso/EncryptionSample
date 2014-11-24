//
//  PCCryptoManager.h
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

extern NSString * const kCryptManagerErrorDomain;

@interface PCCryptoManager : NSObject

/**
 *  Initial Setup
 */
+(void)setUp;


/**
 *  Encryption stream function
 *
 *  @param fromStream parent from stream
 *  @param toStream   conversion stream
 *  @param password   password for encryption
 *  @param error      error object
 *
 *  @return whether data was encrypted or not
 */
+ (BOOL)encryptFromStream:(NSInputStream *)fromStream
                 toStream:(NSOutputStream *)toStream
                 password:(NSString *)password
                    error:(NSError **)error;




/**
 *  Decryption stream function
 *
 *  @param fromStream parent from stream
 *  @param toStream   conversion stream
 *  @param password   password for encryption
 *  @param error      error object
 *
 *  @return whether data was decrypted or not
 */
+ (BOOL)decryptFromStream:(NSInputStream *)fromStream
                 toStream:(NSOutputStream *)toStream
                 password:(NSString *)password
                    error:(NSError **)error;

@end
