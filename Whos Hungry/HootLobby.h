//
//  HootLobby.h
//  Whos Hungry
//
//  Created by administrator on 11/11/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HootLobby : NSObject

@property (strong, nonatomic) NSString* facebookId;
@property (strong, nonatomic) NSString* groupid;
@property (strong, nonatomic) NSString* facebookPic;
@property (strong, nonatomic) NSString* facebookName;
@property (strong, nonatomic) NSMutableArray* facebookbInvitatitions;
@property (strong, nonatomic) NSDate* expirationTime;
@property (strong, nonatomic) NSMutableArray* placesIdArray;
@property (strong, nonatomic) NSMutableArray* placesNamesArray;
@property (strong, nonatomic) NSMutableArray* placesPicsArray;
@property (strong, nonatomic) NSMutableArray* placesXArray;
@property (strong, nonatomic) NSMutableArray* placesYArray;
@property (strong, nonatomic) NSString* voteType;
@property (strong, nonatomic) NSString* voteid;

@property (strong, nonatomic) NSString* winnerRestID;
@property (strong, nonatomic) NSString* winnerRestName;

@end
