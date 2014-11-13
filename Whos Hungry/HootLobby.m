//
//  HootLobby.m
//  Whos Hungry
//
//  Created by administrator on 11/11/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "HootLobby.h"

@implementation HootLobby

- (void)encodeWithCoder:(NSCoder *)encoder
{
    //Encode properties, other class variables, etc
    [encoder encodeObject:_facebookId forKey:@"facebookId"];
    [encoder encodeObject:_facebookbInvitatitions forKey:@"facebookInvitations"];
    [encoder encodeObject:_expirationTime forKey:@"expirationTime"];
    [encoder encodeObject:_placesIdArray forKey:@"placesIdArray"];
    [encoder encodeObject:_voteType forKey:@"voteType"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if( self != nil )
    {
        _facebookId = [decoder decodeObjectForKey:@"facebookId"];
        _facebookbInvitatitions = [decoder decodeObjectForKey:@"facebookInvitations"];
        _expirationTime = [decoder decodeObjectForKey:@"expirationTime"];
        _placesIdArray = [decoder decodeObjectForKey:@"placesIdArray"];
        _voteType = [decoder decodeObjectForKey:@"voteType"];
    }
    return self;
}

@end
