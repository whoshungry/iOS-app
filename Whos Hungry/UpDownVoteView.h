//
//  UpDownVoteView.h
//  Whos Hungry
//
//  Created by Gilad Oved on 11/13/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpDownVoteView : UIView
@property (nonatomic, assign) int votes;
@property (nonatomic, assign) BOOL voted;

@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UILabel *voteLbl;
- (IBAction)voteUp:(id)sender;
- (IBAction)voteDown:(id)sender;

@end
