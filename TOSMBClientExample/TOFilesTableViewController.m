//
//  TOFilesViewControllerTableViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/5/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "TOFilesTableViewController.h"
#import "TOSMBClient.h"
#import "TORootViewController.h"

#import "SMBImageCache.h"

@interface TOFilesTableViewController () <SKAsyncCacheDelegate>

@property (nonatomic, copy) NSString *directoryTitle;
@property (nonatomic, strong) TOSMBSession *session;

@end

@implementation TOFilesTableViewController {
    SMBImageCache *cache;
}

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _directoryTitle = title;
        _session = session;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cache = [SMBImageCache sharedCache];
    
    self.navigationItem.title = @"Loading...";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    cache.delegate = self;
    cache.suspended = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    cache.suspended = YES;
    cache.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    [cell.imageView setImage:nil];
    cell.textLabel.text = file.name;
    cell.detailTextLabel.text = file.directory ? @"Directory" : [NSString stringWithFormat:@"File | Size: %ld", (long)file.fileSize];
    cell.accessoryType = file.directory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    if(!file.directory && [file.name hasSuffix:@".JPG"]) {
        NSArray *key = @[_session, file.filePath];
        
        UIImage *image = [cache objectForKey:key];
        if(image) {
            [cell.imageView setImage:image];
        } else {
            [cache cacheObjectForKey:key];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    if (file.directory == NO) {
        [self.rootController downloadFileFromSession:self.session atFilePath:file.filePath];
        return;
    }
    
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:self.session title:file.name];
    controller.rootController = self.rootController;
    controller.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    [self.navigationController pushViewController:controller animated:YES];
    
    [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
        controller.files = files;
    } error:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }];
}

- (void)setFiles:(NSArray *)files
{
    _files = files;
    self.navigationItem.title = self.directoryTitle;
    [self.tableView reloadData];
}

#pragma mark - SKAsyncCacheDelegate

- (void)asyncCache:(SKAsyncCache *)cache didCacheObject:(id)object forKey:(id<NSCopying>)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)asyncCache:(SKAsyncCache *)cache failedToCacheObjectForKey:(id<NSCopying>)key withError:(NSError *)error {
    NSLog(@"failedToCacheObjectForKey:%@ withError:%@", key, error);
}
         
@end
