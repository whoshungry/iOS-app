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
    [encoder encodeObject:_facebookPic forKey:@"facebookPic"];
    [encoder encodeObject:_facebookName forKey:@"facebookName"];
    [encoder encodeObject:_groupid forKey:@"groupid"];
    [encoder encodeObject:_facebookbInvitatitions forKey:@"facebookInvitations"];
    [encoder encodeObject:_expirationTime forKey:@"expirationTime"];
    [encoder encodeObject:_placesIdArray forKey:@"placesIdArray"];
    [encoder encodeObject:_placesNamesArray forKey:@"placesNamesArray"];
    [encoder encodeObject:_placesPicsArray forKey:@"placesPicsArray"];
    [encoder encodeObject:_placesXArray forKey:@"placesXArray"];
    [encoder encodeObject:_placesYArray forKey:@"placesYArray"];
    [encoder encodeObject:_voteType forKey:@"voteType"];
    [encoder encodeObject:_voteid forKey:@"voteid"];
    [encoder encodeObject:_winnerRestID forKey:@"winnerRestID"];
    [encoder encodeObject:_winnerRestName forKey:@"winnerRestName"];
    [encoder encodeObject:_winnerRestPic forKey:@"winnerRestPic"];
    [encoder encodeObject:_winnerRestX forKey:@"winnerRestX"];
    [encoder encodeObject:_winnerRestY forKey:@"winnerRestY"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if( self != nil )
    {
        _facebookId = [decoder decodeObjectForKey:@"facebookId"];
        _facebookPic = [decoder decodeObjectForKey:@"facebookPic"];
        _facebookName = [decoder decodeObjectForKey:@"facebookName"];
        _groupid = [decoder decodeObjectForKey:@"groupid"];
        _facebookbInvitatitions = [decoder decodeObjectForKey:@"facebookInvitations"];
        _expirationTime = [decoder decodeObjectForKey:@"expirationTime"];
        _placesIdArray = [decoder decodeObjectForKey:@"placesIdArray"];
        _placesNamesArray = [decoder decodeObjectForKey:@"placesNamesArray"];
        _placesPicsArray = [decoder decodeObjectForKey:@"placesPicsArray"];
        _placesXArray = [decoder decodeObjectForKey:@"placesXArray"];
        _placesYArray = [decoder decodeObjectForKey:@"placesYArray"];
        _voteType = [decoder decodeObjectForKey:@"voteType"];
        _voteid = [decoder decodeObjectForKey:@"voteid"];
        _winnerRestID = [decoder decodeObjectForKey:@"winnerRestID"];
        _winnerRestName = [decoder decodeObjectForKey:@"winnerRestName"];
        _winnerRestPic = [decoder decodeObjectForKey:@"winnerRestPic"];
        _winnerRestX = [decoder decodeObjectForKey:@"winnerRestX"];
        _winnerRestY = [decoder decodeObjectForKey:@"winnerRestY"];
    }
    return self;
}

- (NSComparisonResult)compare:(HootLobby *)otherObject {
    return [self.voteid compare:otherObject.voteid];
}


@end
