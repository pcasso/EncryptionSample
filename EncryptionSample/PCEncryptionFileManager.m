//
//  PCEncryptionFileManager
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import "PCEncryptionFileManager.h"
#import "PCCryptoManager.h"

@implementation PCEncryptionFileManager
typedef NS_ENUM (NSInteger, PinProtectionErrorType) {
	PIN_PROTECTION_NO_FILE = 100,
	PIN_PROTECTION_CANNOT_DECRYPT = 200
};


NSString *const kDeviceUUID            = @"DEVICE_UUID";
NSString *const kPinProtectionErrorDomain = @"com.pcasoapps.pinProtectionErrorDomain";

#pragma -
#pragma mark Default pin function

+ (NSString *)defaultPin {
	//1. Read UUID from user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSString *uuid = [userDefaults valueForKey:kDeviceUUID];

	//2. If UUID, not there then save one
	if (!uuid) {
		//3. Generate a UUID
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);

		NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));

		CFRelease(uuidRef);

		uuid = uuidString;

		//4. Save UUID
		[userDefaults setValue:uuid forKey:kDeviceUUID];

		[userDefaults synchronize];
	}

	//5. Return UUID
	return uuid;
}

+ (void)resetDefaultPin {
	//1. Reset UUID in user defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	[userDefaults removeObjectForKey:kDeviceUUID];

	[userDefaults synchronize];
}

#pragma -
#pragma mark File path functions

+ (NSString *)encryptedPathForFileName:(NSString *)fileName {
	//1. Generate file path name

	NSString *fileNameWithExtension = [NSString stringWithFormat:@"%@.dat", fileName];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	NSString *filePath = [paths[0] stringByAppendingPathComponent:fileNameWithExtension];

	return filePath;
}

#pragma -
#pragma mark Encrypt functions

+ (BOOL)encryptDataWithStream:(NSData *)data
                     password:(NSString *)password
                     fileName:(NSString *)fileName
                        error:(NSError **)error {
	//1. Get file path name
	NSString *encryptedPath = [self encryptedPathForFileName:fileName];

	//2. Create input stream
	NSInputStream *inStream = [NSInputStream inputStreamWithData:data];

	[inStream open];

	//3. Create output stream
	NSOutputStream *outStream = [NSOutputStream outputStreamToFileAtPath:encryptedPath
	                                                              append:NO];
	[outStream open];

	//4. Encrypt from input to output stream
	BOOL result = [PCCryptoManager encryptFromStream:inStream
	                                        toStream:outStream
	                                        password:password
	                                           error:error];
	//5. Close file streams
	[inStream close];

	[outStream close];

	//5. Return result
	return result;
}

+ (BOOL)encryptData:(NSData *)data
           fileName:(NSString *)fileName
              error:(NSError **)error {
	return [self encryptDataWithStream:data
	                          password:[self defaultPin]
	                          fileName:fileName
	                             error:error];
}

+ (BOOL)encryptData:(NSData *)data
        withPinCode:(NSString *)pinCode
           fileName:(NSString *)fileName
              error:(NSError **)error {
	return [self encryptDataWithStream:data
	                          password:pinCode
	                          fileName:fileName
	                             error:error];
}

#pragma -
#pragma mark Decrypt functions

+ (NSData *)decryptStreamDataWithPassword:(NSString *)password
                                 fileName:(NSString *)fileName
                                    error:(NSError **)error {
	//1. Get file path name
	NSString *encryptedPath = [self encryptedPathForFileName:fileName];

	//2. Create input stream
	NSInputStream *inStream = [NSInputStream inputStreamWithFileAtPath:encryptedPath];

	[inStream open];

	//3. Create output stream
	NSOutputStream *outStream = [NSOutputStream outputStreamToMemory];

	[outStream open];

	//4. Decrypt from stream
	NSData *data = nil;

	if ([PCCryptoManager decryptFromStream:inStream toStream:outStream password:password error:error]) {
		data = [outStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	}

	//5. Close stream
	[inStream close];

	[outStream close];

	//Return stream data decrypted
	return data;
}

+ (NSData *)decryptDataForFileName:(NSString *)fileName
                             error:(NSError **)error;
{
	return [self decryptDataWithPinCode:[self defaultPin]
	                           fileName:fileName
	                              error:error];
}
+ (NSData *)decryptDataWithPinCode:(NSString *)pinCode
                          fileName:(NSString *)fileName
                             error:(NSError **)error {
	return [self decryptStreamDataWithPassword:pinCode
	                                  fileName:fileName
	                                     error:error];
}

#pragma -
#pragma mark Deletion functions

+ (BOOL)deleteAllEncryptedFiles {
    
    //1. Create file manager
	NSFileManager *manager = [NSFileManager defaultManager];

    //2. Read all  files
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

	NSString *documentsDirectory = paths[0];

	NSArray *allFiles = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];

    //3. Filter encrypted files,
	NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.dat'"];

	NSArray *encryptedFiles = [allFiles filteredArrayUsingPredicate:fltr];

    //4. If not files found ,return
	if (encryptedFiles.count == 0) {
		return YES;
	}

    //5. Loop all encrypted files and delete them
	for (NSString *fileName in encryptedFiles) {
		NSError *error = nil;

		NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];

		[manager removeItemAtPath:filePath error:&error];

		if (error) {
            //6. In case of any error, quit process
			return NO;
		}
	}
    
    //5. Once all files deleted , reset default pin of the application
	[self resetDefaultPin];

    //6. Return success
	return YES;
}

#pragma -
#pragma mark Encrypt file functions
+ (BOOL)saveInformation:(NSDictionary *)dictionary toFile:(NSString *)fileName {
   
    //1. Check for valid object and file name
	if (dictionary && fileName) {
        
        //2. Archive data
		NSData *dictionaryData = [NSKeyedArchiver archivedDataWithRootObject:dictionary];

        //3. Encrypt data in a file
		NSError *error;

		if (![PCEncryptionFileManager encryptData:dictionaryData
		                                 fileName:fileName
		                                    error:&error]) {
			NSLog(@"Could not encrypt data: %@", error);
            
            //4. Return error
			return NO;
		}

        //5. Return success
		return YES;
	}
    
    //5. Return failure (default)
	return NO;
}

#pragma -
#pragma mark Cecrypt file functions

+ (NSDictionary *)decryptFile:(NSString *)fileName withError:(NSError **)error {
	
    //1. Generate data from file manager
    NSData *data = [PCEncryptionFileManager decryptDataForFileName:fileName
	                                                         error:error];

	if (!data) {
        //2. If no data return error for the same
		NSMutableDictionary *details = [NSMutableDictionary dictionary];

		[details setValue:@"No file found" forKey:NSLocalizedDescriptionKey];

		*error = [NSError errorWithDomain:kPinProtectionErrorDomain code:PIN_PROTECTION_NO_FILE userInfo:details];

		return nil;
	}
	else {
		@try {
            //3. If data , generate dictionary output
			NSDictionary *dictionary = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];

			if (dictionary.allKeys.count > 0) {
				return dictionary;
			}
		}
		@catch (NSException *exception)
		{
            //4. For exceptions, raise error

			NSMutableDictionary *details = [NSMutableDictionary dictionary];

			[details setValue:@"Cannot decrypt" forKey:NSLocalizedDescriptionKey];

			*error = [NSError errorWithDomain:kPinProtectionErrorDomain code:PIN_PROTECTION_CANNOT_DECRYPT userInfo:details];
		}
	}
    
    //5. Return nil (default)
    
	return nil;
}

@end
