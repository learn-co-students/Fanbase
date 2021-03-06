//
//  SeeAllNearbyEventsTableViewController.m
//  FanBase
//
//  Created by Andy Novak on 4/18/16.
//  Copyright © 2016 Angelica Bato. All rights reserved.
//

#import "FNBSeeAllNearbyEventsTableViewController.h"
#import "FNBSeeAllNearbyEventsTableViewCell.h"
#import "FNBArtistEvent.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "FNBEventInfoVC.h"
#import "FanBase-Bridging-Header.h"
#import "FanBase-Swift.h"
#import "FNBColorConstants.h"

@interface FNBSeeAllNearbyEventsTableViewController () 

//@property (nonatomic,strong)SideBar *sideBar;

@end

@implementation FNBSeeAllNearbyEventsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    //Initializes hamburger bar menu button
    UIBarButtonItem *hamburgerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleDone target:self action:@selector(hamburgerButtonTapped:)];
    self.navigationItem.rightBarButtonItem = hamburgerButton;
    
    //Gradient
    self.view.tintColor = FNBOffWhiteColor;
    UIColor *gradientMaskLayer = FNBLightGreenColor;
    CAGradientLayer *gradientMask = [CAGradientLayer layer];
    gradientMask.frame = self.view.bounds;
    gradientMask.colors = @[(id)gradientMaskLayer.CGColor,(id)[UIColor clearColor].CGColor];
    
    [self.view.layer insertSublayer:gradientMask atIndex:0];
    
}


// Side bar delegate method implementation
-(void)didSelectButtonAtIndex:(NSInteger)index {
    
    NSLog(@"%ld", (long)index);
    
    if ((long)index == 0) {
        FNBSeeAllNearbyEventsTableViewController *userProfileVC = [[UIStoryboard storyboardWithName:@"UserPage" bundle:nil] instantiateViewControllerWithIdentifier:@"UserPageID"];
        // Push eventInfoVC in my window
        [self.navigationController pushViewController:userProfileVC animated:YES];
    } else if ((long)index == 1) {
        FNBSeeAllNearbyEventsTableViewController *discoverPageVC = [[UIStoryboard storyboardWithName:@"Discover2" bundle:nil]instantiateViewControllerWithIdentifier:@"DiscoverPageID"];
        // Push eventInfoVC in my window
        [self.navigationController pushViewController:discoverPageVC animated:YES];
    } else if ((long)index == 2) {
        FNBSeeAllNearbyEventsTableViewController *eventsVC = [[UIStoryboard storyboardWithName:@"FNBArtistNews" bundle:nil]instantiateViewControllerWithIdentifier:@"eventInfo"];
        // Push eventInfoVC in my window
        [self.navigationController pushViewController:eventsVC animated:YES];
    }
}


// If bar menu is tapped
-(void)hamburgerButtonTapped:(id)sender {
    NSLog(@"Hamburger pressed and posting notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HamburgerButtonNotification" object:nil];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        FNBArtistEvent *selectedEvent = self.receivedConcertsArray[indexPath.row];
        
        
        // Create an instance of FNBEventInfoVC (view controller)
        // Use UIStoryboard class/type to create the instance
        FNBEventInfoVC *eventInfoVC = [[UIStoryboard storyboardWithName:@"FNBArtistNews" bundle:nil] instantiateViewControllerWithIdentifier:@"eventInfo"];
        
        // Assign event value to property on eventInfoVC
        eventInfoVC.event = selectedEvent;
        
        // Push eventInfoVC in my window
        [self.navigationController pushViewController:eventInfoVC animated:YES];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.receivedConcertsArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FNBSeeAllNearbyEventsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.eventDateLabel.text = ((FNBArtistEvent *)self.receivedConcertsArray[indexPath.row]).dateOfConcert;
    cell.eventTitleLabel.text = ((FNBArtistEvent *)self.receivedConcertsArray[indexPath.row]).eventTitle;
    [cell.eventImage setImageWithURL:[NSURL URLWithString: ((FNBArtistEvent *)self.receivedConcertsArray[indexPath.row]).artistImageURL]];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.backgroundView.backgroundColor = FNBLightGreenColor;
}


@end
