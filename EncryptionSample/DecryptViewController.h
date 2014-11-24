//
//  DecryptViewController.h
//  Encryption
//
//  Created by Prashant Choudhary on 15/11/14.
//  Copyright (c) 2014 PC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DecryptViewController : UIViewController

//Textview
@property (weak, nonatomic) IBOutlet UITextView *textView;
//Decrypt Button
@property (weak, nonatomic) IBOutlet UIButton *decryptButton;

- (IBAction)decrypt:(id)sender;
- (IBAction)clear:(id)sender;

@end
