//
//  SMBImageCache.m
//  TOSMBClientExample
//
//  Created by Shin-Kai Chen on 2016/4/11.
//  Copyright © 2016年 TimOliver. All rights reserved.
//

#import "SMBImageCache.h"

#import "TOSMBClient.h"

@interface SMBImageCache () <SKAsyncCacheLoader, TOSMBSessionDownloadTaskDelegate>

@end

@implementation SMBImageCache {
    SKTaskQueue *fileDownloadQueue;
    SKFileCache *fileCache;
    
    TOSMBSessionDownloadTask *downloadTask;
    SuccessBlock downloadSuccessBlock;
    FailureBlock downloadFailureBlock;
}

+ (nonnull instancetype)sharedCache {
    static SMBImageCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (nonnull instancetype)init {
    fileDownloadQueue = [[SKTaskQueue alloc] initWithOrderedDictionary:nil andConstraint:20 andQueue:nil];
    
    NSString *cachePath = [self tempPathForCache];
    
    fileCache = [[SKFileCache alloc] initWithPath:cachePath andConstraint:100 andCoster:nil andLoader:self andTaskQueue:fileDownloadQueue];
    return [self initWithFileCache:fileCache andConstraint:50 andCoster:nil andLoader:nil andTaskQueue:nil];
}

#pragma mark - SKAsyncCacheLoader

- (void)loadObjectForKey:(id<NSCopying>)key success:(SuccessBlock)success failure:(FailureBlock)failure {

    NSArray *parameters = (NSArray *)key;
    TOSMBSession *session = [parameters objectAtIndex:0];
    NSString *filePath = [parameters objectAtIndex:1];
    
    downloadSuccessBlock = [success copy];
    downloadFailureBlock = [failure copy];
    
    NSString *destinationPath = [self tempPathForSession:session andPath:filePath];
    
    downloadTask = [session downloadTaskForFileAtPath:filePath destinationPath:destinationPath delegate:self];
    [downloadTask resume];
}

#pragma mark - TOSMBSessionDownloadTaskDelegate

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didFinishDownloadingToPath:(NSString *)destinationPath {
    downloadSuccessBlock(destinationPath);
}

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error {
    downloadFailureBlock(error);
}

#pragma mark - Misc

- (NSString *)tempPathForCache {
    NSArray *cacheDirectorys = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cacheDirectorys objectAtIndex:0];
    return [cacheDirectory stringByAppendingPathComponent:@"fileCache.plist"];
}

- (NSString *)tempPathForSession:(TOSMBSession *)session andPath:(NSString *)path {
    NSArray *cacheDirectorys = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [cacheDirectorys objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", session.hostName, [[path stringByReplacingOccurrencesOfString:@"/" withString:@"-"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return [cacheDirectory stringByAppendingPathComponent:fileName];
}

@end
