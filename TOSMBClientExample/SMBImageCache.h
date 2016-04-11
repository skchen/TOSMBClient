//
//  SMBImageCache.h
//  TOSMBClientExample
//
//  Created by Shin-Kai Chen on 2016/4/11.
//  Copyright © 2016年 TimOliver. All rights reserved.
//

@import SKImageCache;

@interface SMBImageCache : SKAsyncImageCache

+ (nonnull instancetype)sharedCache;

@end
