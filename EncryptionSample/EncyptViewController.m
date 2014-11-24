//
//  EncyptViewController.h
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//


#import "EncyptViewController.h"
#import "PCEncryptionFileManager.h"
#import "PCPinProtectionManager.h"


@implementation EncyptViewController


- (void)viewDidLoad {
	[super viewDidLoad];

	self.textView.editable = NO;
	self.textView.text = @"";
	self.encryptButton.enabled = YES;
}

-(IBAction)savePinCode:(id)sender
{
    NSString *pinCode=@"1234";
   
    BOOL pinWasSaved=[PCPinProtectionManager savePinCode:pinCode];
    
    self.textView.text=pinWasSaved?[NSString stringWithFormat:@"SAVED: %@",pinCode]:@"Could not save";
}

- (IBAction)encrypt:(id)sender {
	
    NSString *random=[NSString stringWithFormat:@"Test %d",arc4random()%1000];
    
    NSArray *array = @[@"test1", @"testk", @"test3",random];
	
    NSDictionary *dictionary = @{@"ROOT": array};
    
    if ([PCEncryptionFileManager saveInformation:dictionary toFile:@"MY_TASKS"]) {
        
        self.textView.text = dictionary.description;

    }else{
        self.textView.text = @"Could not write";
    }
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

@end
