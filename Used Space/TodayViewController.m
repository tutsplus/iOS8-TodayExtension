//
//  TodayViewController.m
//  Used Space
//
//  Created by Cesar Tessarin on 06/10/14.
//  Copyright (c) 2014 CMT. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#define RATE_KEY @"kUDRateUsed"

#define kWClosedHeight   37.0
#define kWExpandedHeight 106.0

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *barView;
@property (weak, nonatomic) IBOutlet UILabel *detailsLabel;

@property (nonatomic, assign) unsigned long long fileSystemSize;
@property (nonatomic, assign) unsigned long long freeSize;
@property (nonatomic, assign) unsigned long long usedSize;
@property (nonatomic, assign) double usedRate;
@end

@implementation TodayViewController

#pragma mark - Custom Accessors

- (double)usedRate
{
    return [[[NSUserDefaults standardUserDefaults]
             valueForKey:RATE_KEY] doubleValue];
}

- (void)setUsedRate:(double)usedRate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithDouble:usedRate]
                forKey:RATE_KEY];
    [defaults synchronize];
}

#pragma mark - Widget

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)margins
{
    margins.bottom = 10.0;
    return margins;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    
    [self updateSizes];
    
    double newRate = (double)self.usedSize / (double)self.fileSystemSize;
    
    if (newRate - self.usedRate < 0.0001) {
        completionHandler(NCUpdateResultNoData);
    } else {
        [self setUsedRate:newRate];
        [self updateInterface];
        completionHandler(NCUpdateResultNewData);
    }
}

#pragma mark - Update Helpers

- (void)updateSizes
{
    // Retrieve the dictionary with the attributes from NSFileManager
    NSDictionary *dict = [[NSFileManager defaultManager]
                          attributesOfFileSystemForPath:NSHomeDirectory()
                          error:nil];
    
    // Set the values
    self.fileSystemSize = [[dict valueForKey:NSFileSystemSize]
                           unsignedLongLongValue];
    self.freeSize       = [[dict valueForKey:NSFileSystemFreeSize]
                           unsignedLongLongValue];
    self.usedSize       = self.fileSystemSize - self.freeSize;
}

- (void)updateInterface
{
    double rate = self.usedRate; // retrieve the cached value
    self.percentLabel.text = [NSString stringWithFormat:@"%.1f%%", (rate * 100)];
    self.barView.progress = rate;
}

-(void)updateDetailsLabel
{
    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    [formatter setCountStyle:NSByteCountFormatterCountStyleFile];
    
    self.detailsLabel.text =
    [NSString stringWithFormat:@"Used:\t%@\nFree:\t%@\nTotal:\t%@",
     [formatter stringFromByteCount:self.usedSize],
     [formatter stringFromByteCount:self.freeSize],
     [formatter stringFromByteCount:self.fileSystemSize]];
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateInterface];
    [self setPreferredContentSize:CGSizeMake(0.0, kWClosedHeight)];
    [self.detailsLabel setAlpha:0.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         [self.detailsLabel setAlpha:1.0];
     } completion:nil];
}

#pragma mark - Touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateDetailsLabel];
    [self setPreferredContentSize:CGSizeMake(0.0, kWExpandedHeight)];
}

@end
