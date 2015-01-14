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
    self.state++;
    if (self.state == 0) {
        self.votes++;
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    } else if (self.state == 1) {
        self.upBtn.enabled = NO;
        self.downBtn.enabled = YES;
        self.votes++;
    }
    self.status = @"+1";
    self.voteLbl.text = [NSString stringWithFormat:@"%i", self.votes];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:self
                                                         forKey:@"sender"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeVote" object:self userInfo:dataDict];
}

- (IBAction)voteDown:(id)sender {
    self.state--;
    if (self.state == -1) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = NO;
        self.votes--;
    } else if (self.state == 0) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
        self.votes--;
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES
        ;
    }
    self.status = @"-1";
    self.voteLbl.text = [NSString stringWithFormat:@"%i", self.votes];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:self
                                                         forKey:@"sender"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeVote" object:self userInfo:dataDict];
}

-(void) enableDisable:(int)property {
    if (property == -1) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = NO;
    } else if (property == 0) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    } else if (property == 1) {
        self.upBtn.enabled = NO;
        self.downBtn.enabled = YES;
    }
}

-(void) setVoteLbl:(UILabel *)voteLbl {
    self.voteLbl = voteLbl;
    if ([voteLbl.text isEqualToString:@"-1"]) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = NO;
    } else if ([voteLbl.text isEqualToString:@"0"]) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    } else if ([voteLbl.text isEqualToString:@"1"]) {
        self.upBtn.enabled = NO;
        self.downBtn.enabled = YES;
    }
}



@end
