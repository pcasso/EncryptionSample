//
//  PCCryptoManager.m
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import "PCCryptoManager.h"


NSString *const kCryptoManagerErrorDomain = @"com.pcasso.encryptionErrorDomain";
NSString *const kApplicationSalt          = @"KeyApplicationSalt";

const CCAlgorithm kAlgorithm              = kCCAlgorithmAES128;
const NSUInteger kAlgorithmKeySize        = kCCKeySizeAES256;
const NSUInteger kPBKDFSaltSize           = 32;
const NSUInteger kNumberOfRound           = 10000;
static const NSUInteger kMaxReadSize      = 1024;

#pragma -
#pragma mark Output stream
@interface NSOutputStream (Data)
- (BOOL)writeData:(NSData *)data error:(NSError **)error;
@end

@implementation NSOutputStream (Data)
- (BOOL)writeData:(NSData *)data error:(NSError **)error {
	//1. If data, write data to stream
	if (data.length > 0) {
		NSInteger bytesWritten = [self   write:data.bytes
		                             maxLength:data.length];
		if (bytesWritten != data.length) {
			if (error) {
				*error = [self streamError];
			}
			return NO;
		}
	}
	return YES;
}

@end

#pragma -
#pragma mark Input stream
@interface NSInputStream (Data)
- (BOOL)getData:(NSData **)data
      maxLength:(NSUInteger)maxLength
          error:(NSError **)error;
@end

@implementation NSInputStream (Data)

- (BOOL)getData:(NSData **)data
      maxLength:(NSUInteger)maxLength
          error:(NSError **)error {
	
    //1. Read stream
	NSMutableData *buffer = [NSMutableData dataWithLength:maxLength];
	if ([self read:buffer.mutableBytes maxLength:maxLength] < 0) {
		if (error) {
			*error = [self streamError];
			return NO;
		}
	}

	*data = buffer;
	return YES;
}

@end

@implementation PCCryptoManager
#pragma -
#pragma mark Initialize Functions

+ (void)setUp {
	//1. Fetch Salt.
	NSString *fetchSalt = [self fetchSalt];

	//2. In case of no salt, generate one
	if (!fetchSalt) {
		[self generateSalt];
	}
}

#pragma -
#pragma mark Salt Functions
+ (NSString *)fetchSalt {
	//1. Return salt from user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	return [userDefaults objectForKey:kApplicationSalt];
}

+ (NSData *)fetchSaltData {
	//1. Return salt
	NSString *salt = [self fetchSalt];
	if (!salt) {
		//2. If no salt, generate one
		salt = [self generateSalt];
	}
	// 3. Generate data from salt
	NSData *data = [[NSData alloc]initWithBase64EncodedString:salt options:0];
	return data;
}

+ (NSString *)generateSalt {
	// 1. Clear salt if existing
	[self clearSalt];

	//2.Gnerate salt of length kPBKDFSaltSize
	NSData *saltData = [self randomDataOfLength:kPBKDFSaltSize];

	//3. Convert to string
	NSString *salt = [saltData base64EncodedStringWithOptions:0];

	//4. Save string in user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:salt forKey:kApplicationSalt];
	[userDefaults synchronize];

	//5. return salt
	return salt;
}

+ (void)clearSalt {
	//1. Clear salt from user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults removeObjectForKey:kApplicationSalt];
	[userDefaults synchronize];
}

#pragma -
#pragma mark Random Functions
+ (NSData *)randomDataOfLength:(size_t)length {
    
    //1. Create data
	NSMutableData *data = [NSMutableData dataWithLength:length];

    //2. Create result by copying bytes
	NSInteger result = SecRandomCopyBytes(kSecRandomDefault,
	                                      length,
	                                      data.mutableBytes);
	NSAssert(result == 0, @"Unable to generate random bytes: %d",
	         errno);

	return data;
}

#pragma -
#pragma mark AES Key
+ (NSData *)AESKeyForPassword:(NSString *)password
                         salt:(NSData *)salt {
    
    //1. Generate derived key

	NSMutableData *derivedKey = [NSMutableData dataWithLength:kAlgorithmKeySize];

    //2. Generate result from CCKeyDerivationPBKDF function
	NSInteger result = CCKeyDerivationPBKDF(kCCPBKDF2,    // algorithm
	                                        password.UTF8String, // password
	                                        password.length, // passwordLength
	                                        salt.bytes,   // salt
	                                        salt.length,  // salt length
	                                        kCCPRFHmacAlgSHA256, // SHA256
	                                        kNumberOfRound, // rounds
	                                        derivedKey.mutableBytes, // derivedKey
	                                        derivedKey.length); // derivedKeyLen


	NSAssert(result == kCCSuccess,
	         @"Unable to create AES key for password: %ld", (long)result);

    //3. Return key
	return derivedKey;
}

#pragma -
#pragma mark Private functions
+ (BOOL)processResult:(CCCryptorStatus)result
                bytes:(uint8_t *)bytes
               length:(size_t)length
             toStream:(NSOutputStream *)outStream
                error:(NSError **)error {
    
    //1. If result is unsuccessful, return error
	if (result != kCCSuccess) {
		if (error) {
			*error = [NSError errorWithDomain:kCryptoManagerErrorDomain
			                             code:result
			                         userInfo:nil];
		}
		NSLog(@"Could not process data: %d", result);
		return NO;
	}

    //2. If length is fine , write it to stream
	if (length > 0) {
		if ([outStream write:bytes maxLength:length] != length) {
			if (error) {
				*error = [outStream streamError];
			}
			return NO;
		}
	}
	return YES;
}

+ (BOOL)applyOperation:(CCOperation)operation
            fromStream:(NSInputStream *)inStream
              toStream:(NSOutputStream *)outStream
              password:(NSString *)password
                 error:(NSError **)error {
	NSAssert([inStream streamStatus] != NSStreamStatusNotOpen,
	         @"fromStream must be open");
	NSAssert([outStream streamStatus] != NSStreamStatusNotOpen,
	         @"toStream must be open");
	NSAssert([password length] > 0,
	         @"Can't proceed with no password");

	// 1. Generate the salt, or read them from the stream
	NSData *salt = [self fetchSaltData];
    
    //2. Encrypt or decrypt
	switch (operation) {
		case kCCEncrypt:
            //3. Write data to stream
            if (![outStream writeData:salt error:error]) {
				return NO;
			}
			break;

		case kCCDecrypt:
			//4.  Read the salt from the encrypted file
			if (![inStream getData:&salt
			             maxLength:kPBKDFSaltSize
			                 error:error]) {
				return NO;
			}
			break;

		default:
			NSAssert(NO, @"Unknown operation: %d", operation);
			break;
	}

    //5. Generate Master key
	NSData *masterKey = [self AESKeyForPassword:password salt:salt];

	// Create the cryptor
	CCCryptorRef cryptor = NULL;
	CCCryptorStatus result;
	result = CCCryptorCreate(operation,             // operation
	                         kAlgorithm,            // algorithim
	                         kCCOptionPKCS7Padding, // options
	                         masterKey.bytes,       // key
	                         masterKey.length,      // keylength
	                         salt.bytes,            // salt
	                         &cryptor);             // OUT cryptorRef

    //6. In case of a falure , raise error
	if (result != kCCSuccess || cryptor == NULL) {
		if (error) {
			*error = [NSError errorWithDomain:kCryptoManagerErrorDomain
			                             code:result
			                         userInfo:nil];
		}
		NSAssert(NO, @"Could not create cryptor: %d", result);
		return NO;
	}

    //6. For success, write data
    size_t dstBufferSize = MAX(CCCryptorGetOutputLength(cryptor, // cryptor
	                                                    kMaxReadSize, // input length
	                                                    true), // final
	                           kMaxReadSize);

	NSMutableData *dstData = [NSMutableData dataWithLength:dstBufferSize];

	NSMutableData *srcData = [NSMutableData dataWithLength:kMaxReadSize];

	uint8_t *srcBytes = srcData.mutableBytes;
	uint8_t *dstBytes = dstData.mutableBytes;

	//7. Read and write the file data in blocks
	ssize_t srcLength;
	size_t dstLength = 0;

    //8. Encrypt / Decrypt data in block
	while ((srcLength = [inStream read:srcBytes
	                         maxLength:kMaxReadSize]) > 0) {
		result = CCCryptorUpdate(cryptor,       // cryptor
		                         srcBytes,      // dataIn
		                         srcLength,     // dataInLength
		                         dstBytes,      // dataOut
		                         dstBufferSize, // dataOutAvailable
		                         &dstLength);   // dataOutMoved

		if (![self processResult:result
		                   bytes:dstBytes
		                  length:dstLength
		                toStream:outStream
		                   error:error]) {
			CCCryptorRelease(cryptor);
			return NO;
		}
	}
    
    //9. For writing stream error , notify
	if (srcLength != 0) {
		if (error) {
			*error = [inStream streamError];
			return NO;
		}
	}

	// 10. Write the final block
	result = CCCryptorFinal(cryptor,      // cryptor
	                        dstBytes,     // dataOut
	                        dstBufferSize, // dataOutAvailable
	                        &dstLength);  // dataOutMoved
	if (![self processResult:result
	                   bytes:dstBytes
	                  length:dstLength
	                toStream:outStream
	                   error:error]) {
		CCCryptorRelease(cryptor);
		return NO;
	}

    //11. release resources
	CCCryptorRelease(cryptor);
    
    //12. returns success
	return YES;
}

#pragma -
#pragma mark Encrypt functions
+ (BOOL)encryptFromStream:(NSInputStream *)fromStream
                 toStream:(NSOutputStream *)toStream
                 password:(NSString *)password
                    error:(NSError **)error {
	return [self applyOperation:kCCEncrypt
	                 fromStream:fromStream
	                   toStream:toStream
	                   password:password
	                      error:error];
}

#pragma -
#pragma mark Decrypt functions

+ (BOOL)decryptFromStream:(NSInputStream *)fromStream
                 toStream:(NSOutputStream *)toStream
                 password:(NSString *)password
                    error:(NSError **)error {
	return [self applyOperation:kCCDecrypt
	                 fromStream:fromStream
	                   toStream:toStream
	                   password:password
	                      error:error];
}

@end
