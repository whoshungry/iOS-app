//
//  UpDownVoteView.m
//  Whos Hungry
//
//  Created by Gilad Oved on 11/13/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "UpDownVoteView.h"

@implementation UpDownVoteView

- (IBAction)voteUp:(id)sender {
    if (!self.voted) {
        self.voted = YES;
        self.votes++;
        self.upBtn.enabled = NO;
    }
}

- (IBAction)voteDown:(id)sender {
    if (!self.voted) {
        self.voted = YES;
        self.votes--;
        self.downBtn.enabled = NO;
    }
}

-(void) setVotes:(int)votes {
    self.votes = votes;
    self.voteLbl.text = [NSString stringWithFormat:@"%i", votes];
}


@end
