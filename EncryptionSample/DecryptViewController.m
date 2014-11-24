//
//  DecryptViewController.m
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import "DecryptViewController.h"
#import <CommonCrypto/CommonCryptor.h>
#import "PCEncryptionFileManager.h"
#import "PCPinProtectionManager.h"

@implementation DecryptViewController
- (void)viewDidLoad {
    
	[super viewDidLoad];
	
    self.textView.text = @"";
	self.textView.editable = NO;
	self.decryptButton.enabled = YES;
    
}

- (IBAction)decryptPin:(id)sender {
   
    NSString *pinCode=@"1234";
    
    BOOL isValidPinCode =[PCPinProtectionManager isValidPinCode:pinCode];
    
    BOOL hasPinCode=[PCPinProtectionManager hasPinCode];
    
    if (hasPinCode) {
        
        NSInteger incorrectPinCount=[PCPinProtectionManager incorrectPinCount];
        
        self.textView.text =isValidPinCode?pinCode:[NSString stringWithFormat:@"Not valid pin, incorrectPinCount: %ld",incorrectPinCount];
    }else{
       
        self.textView.text =@"No Pin";

    }

}

- (IBAction)decrypt:(id)sender {
	
    NSError *error=nil;
    
    NSDictionary *dictionary=[PCEncryptionFileManager decryptFile:@"MY_TASKS" withError:&error];
    
    if (dictionary) {
        
        self.textView.text = dictionary.description;
    }else {
        
        self.textView.text = [NSString stringWithFormat:@"Error: %ld ",error.code];
    }
    return;
    
}
- (IBAction)clear:(id)sender{
    [PCEncryptionFileManager deleteAllEncryptedFiles];
    [PCPinProtectionManager resetIncorrectPinCount];

    [self decrypt:nil];
}


- (void)viewDidUnload {
	[super viewDidUnload];
}

@end
