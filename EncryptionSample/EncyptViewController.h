//
//  EncyptViewController.h
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EncyptViewController : UIViewController;
//Textview
@property (weak, nonatomic) IBOutlet UITextView *textView;
//Button
@property (weak, nonatomic) IBOutlet UIButton *encryptButton;


- (IBAction)encrypt:(id)sender;

@end
