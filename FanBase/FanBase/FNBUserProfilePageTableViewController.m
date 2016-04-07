//
//  FNBUserProfilePageTableViewController.m
//  FanBase
//
//  Created by Andy Novak on 4/5/16.
//  Copyright © 2016 Angelica Bato. All rights reserved.
//

#import "FNBUserProfilePageTableViewController.h"
#import "FNBFirebaseClient.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <QuartzCore/QuartzCore.h>

@interface FNBUserProfilePageTableViewController ()

@property (strong, nonatomic) FNBUser *currentUser;

@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *numberOfSubscribedArtistsLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistXOfTotalLabel;

@property (weak, nonatomic) IBOutlet UIImageView *artist1ImageView;
@property (weak, nonatomic) IBOutlet UILabel *artist1NameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artist1XOfTotalFans;

@property (weak, nonatomic) IBOutlet UIImageView *artist2ImageView;
@property (weak, nonatomic) IBOutlet UILabel *artist2NameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artist2XOfTotalFans;

@property (weak, nonatomic) IBOutlet UIImageView *artist3ImageView;
@property (weak, nonatomic) IBOutlet UILabel *artist3NameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artist3XOfTotalFans;

@property (weak, nonatomic) IBOutlet UIImageView *artist4ImageView;
@property (weak, nonatomic) IBOutlet UILabel *artist4NameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artist4XOfTotalFans;

@property (weak, nonatomic) IBOutlet UITableViewCell *artist1TableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *artist2TableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *artist3TableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *artist4TableViewCell;

@property (strong, nonatomic) NSArray *arrayOfArtistLabels;
@property (strong, nonatomic) NSArray *arrayOfArtistImageViews;
@property (strong, nonatomic) NSArray *arrayOfArtistRankingLabels;

@property (strong, nonatomic) Firebase *userRef;

@end

@implementation FNBUserProfilePageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set the artistLabels and artistImageViews of the cells
    self.arrayOfArtistLabels = @[self.artist1NameLabel, self.artist2NameLabel, self.artist3NameLabel, self.artist4NameLabel];
    self.arrayOfArtistImageViews = @[self.artist1ImageView, self.artist2ImageView, self.artist3ImageView, self.artist4ImageView];
    self.arrayOfArtistRankingLabels = @[self.artist1XOfTotalFans, self.artist2XOfTotalFans, self.artist3XOfTotalFans, self.artist4XOfTotalFans];
    
    
    
    // make user image rounded
    self.userImageView.layer.cornerRadius = self.userImageView.frame.size.height / 2;
    self.userImageView.layer.masksToBounds = YES;
    
    // make artist images circular
    for (UIImageView *artistImage in self.arrayOfArtistImageViews) {
        artistImage.layer.cornerRadius = artistImage.frame.size.height / 2;
        artistImage.layer.masksToBounds = YES;
    }
    
    // set user info, and then get a detailed array of the artists the user is subscribed to
    
    self.currentUser = [[FNBUser alloc] init];
    [FNBFirebaseClient setPropertiesOfLoggedInUserToUser:self.currentUser withCompletionBlock:^(BOOL completedSettingUsersProperties) {
        if (completedSettingUsersProperties) {
            
            // get an array of artists that the user is subscribed to filled with detailed info
            [FNBFirebaseClient getADetailedArtistArrayFromUserArtistDictionary:self.currentUser.artistsDictionary withCompletionBlock:^(BOOL gotDetailedArray, NSArray *arrayOfArtists) {
                if (gotDetailedArray) {
                    self.currentUser.detailedArtistInfoArray = arrayOfArtists;
                    
                    // get users rankings for each of their subscribed artists
                    self.currentUser.rankingForEachArtist = [self getArtistInfoForLabels:self.currentUser];
                    
                    [self updateUI];
                }
            }];
        }
    }];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    
    // start listening to changes in the username, userProfileImage, or artistDictionary
    
    NSString *urlOfUser= [NSString stringWithFormat:@"%@/users/%@", ourFirebaseURL, self.currentUser.userID];
    NSLog(@"url of user: %@", urlOfUser);
    self.userRef = [[Firebase alloc] initWithUrl:urlOfUser];
    [self.userRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"this is the new value: %@, and this is the key: %@", snapshot.value, snapshot.key);
        // change in username
        if ([snapshot.key isEqualToString:@"userName"]) {
            self.currentUser.userName = snapshot.value;
            [self updateUI];
        }
        // change in the profileImageURL
        else if ([snapshot.key isEqualToString:@"profileImageURL"]){
            self.currentUser.profileImageURL = snapshot.value;
            [self updateUI];
        }
        // change in the artistDictionary
        else if ([snapshot.key isEqualToString:@"artistsDictionary"]){
            self.currentUser.artistsDictionary = snapshot.value;
            [FNBFirebaseClient getADetailedArtistArrayFromUserArtistDictionary:self.currentUser.artistsDictionary withCompletionBlock:^(BOOL gotDetailedArray, NSArray *arrayOfArtists) {
                if (gotDetailedArray) {
                    self.currentUser.detailedArtistInfoArray = arrayOfArtists;
                    [self updateUI];
                }
            }];
        }
        
    }];
}

//-(void)viewWillDisappear:(BOOL)animated{
//    [super viewWillDisappear:animated];
//    [self.userRef removeAllObservers];
//}

- (NSArray *) getArtistInfoForLabels:(FNBUser *)user {
    // figure out rank for each artist in array
    NSMutableArray *arrayToFill = [NSMutableArray new];
    for (FNBArtist *artist in user.detailedArtistInfoArray) {
        //                        NSLog(@"this is artist %@, and their subscribed Users: %@", artist.name, artist.subscribedUsers);
        // create an array of dictionaries
        NSMutableArray *subscribedUsersArray = [NSMutableArray new];
        for (NSString *key in artist.subscribedUsers) {
            NSDictionary *result = @{ @"userID" : key ,
                                      @"points" : [artist.subscribedUsers objectForKey:key]
                                      };
            [subscribedUsersArray addObject:result];
        }
        // now sort this array by points
        NSSortDescriptor *pointsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"points" ascending:NO];
        NSArray *sortedArray = [subscribedUsersArray sortedArrayUsingDescriptors:@[pointsDescriptor]];
        //                        NSLog(@"artist: %@ and their array of users: %@", artist.name, sortedArray);
        
        // now find what number current user is in the array
        NSInteger currentUsersRank = [sortedArray indexOfObjectPassingTest:^BOOL(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
            return [[dict objectForKey:@"userID"] isEqual:self.currentUser.userID];
        }];
        NSDictionary *rankingDictionary = @{
                                            @"artistName" : artist.name ,
                                            @"usersRank" : @(currentUsersRank + 1),
                                            @"numberOfFollowers" : @(sortedArray.count),
                                            @"artistImageURL" : artist.imagesArray[0][@"url"]
                                            };
        [arrayToFill addObject:rankingDictionary];
//        NSLog(@"users rank for artist: %@ is: %li out of %li", artist.name,currentUsersRank + 1, sortedArray.count);
    }
    NSLog(@"%@", arrayToFill);
    return arrayToFill;
}


- (IBAction)userNameDoubleTapped:(id)sender {
    // pull up an alert to change userName
    UIAlertController *changeNameAlert = [UIAlertController alertControllerWithTitle:@"Change Username" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeNameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Username Placeholder", @"Username");
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *username = changeNameAlert.textFields.firstObject;
//        NSLog(@"this is the username: %@", username.text);
        // change the userName in the Database
        [FNBFirebaseClient changeUserNameOfUser:self.currentUser toName:username.text withCompletionBlock:^(BOOL completedChangingUserName) {
            if (completedChangingUserName) {
                [self updateUI];
            }
        }];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [changeNameAlert addAction:submitAction];
    [changeNameAlert addAction:cancel];
    submitAction.enabled = NO;
    [self presentViewController:changeNameAlert animated:YES completion:nil];
    
}
// makes Submit button disabled unless there is text in the textField
- (void) alertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField *userName = alertController.textFields.firstObject;
        UIAlertAction *submitAction = alertController.actions.firstObject;
        submitAction.enabled = userName.text.length > 0;
    }
}
- (IBAction)profilePictureDoubleTapped:(id)sender {
    // pull up an alert to change profilePic
    UIAlertController *changeProfilePictureAlert = [UIAlertController alertControllerWithTitle:@"Change Profile Picture" message:@"Enter URL:" preferredStyle:UIAlertControllerStyleAlert];
    [changeProfilePictureAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Image URL Placeholder", @"Image URL (make sure its https");
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *imageURLTextField = changeProfilePictureAlert.textFields.firstObject;

        // change the profilePicURL in the Database
        [FNBFirebaseClient changeProfilePictureURLOfUser:self.currentUser toURL:imageURLTextField.text withCompletionBlock:^(BOOL completedChangingProfilePicURL) {
            if (completedChangingProfilePicURL) {
                [self updateUI];
            }
        }];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [changeProfilePictureAlert addAction:submitAction];
    [changeProfilePictureAlert addAction:cancel];
    submitAction.enabled = NO;
    [self presentViewController:changeProfilePictureAlert animated:YES completion:nil];
}


- (void) updateUI {
    self.userNameLabel.text = self.currentUser.userName;
    [self.userImageView setImageWithURL:[NSURL URLWithString:self.currentUser.profileImageURL]];
    self.numberOfSubscribedArtistsLabel.text = [NSString stringWithFormat: @"Number of Artists: %lu", self.currentUser.artistsDictionary.count];
    // TODO: put in the biggest fan label here
    
    [self setLabelsAndImagesOfArtistCells:self.currentUser.rankingForEachArtist];

    self.tableView.tableFooterView = [UIView new];
    [self.tableView reloadData];
}


- (void)setLabelsAndImagesOfArtistCells:(NSArray *)artistInfoArray {
    NSUInteger numberOfArtists = artistInfoArray.count;
    if (numberOfArtists == 0) {
        NSLog(@"there are no artists for this user according to the detailedArtistArray");
    }
    // user is subscribed to less than or equal number of artists than there are labels
    else if (numberOfArtists <= self.arrayOfArtistLabels.count) {
        for (NSInteger i = 0; i < numberOfArtists; i++) {
            ((UILabel *)self.arrayOfArtistLabels[i]).text = artistInfoArray[i][@"artistName"];
            [((UIImageView *)self.arrayOfArtistImageViews[i]) setImageWithURL:[NSURL URLWithString:artistInfoArray[i][@"artistImageURL"]]];
            ((UILabel *)self.arrayOfArtistRankingLabels[i]).text = [NSString stringWithFormat:@"#%@ of %@", artistInfoArray[i][@"usersRank"], artistInfoArray[i][@"numberOfFollowers" ]];
        }
    }
    // user is subscribed to more artists than there are labels
    else {
        for (NSInteger i = 0; i < self.arrayOfArtistLabels.count; i++) {
            ((UILabel *)self.arrayOfArtistLabels[i]).text = artistInfoArray[i][@"artistName"];
            [((UIImageView *)self.arrayOfArtistImageViews[i]) setImageWithURL:[NSURL URLWithString:artistInfoArray[i][@"artistImageURL"]]];
            ((UILabel *)self.arrayOfArtistRankingLabels[i]).text = [NSString stringWithFormat:@"#%@ of %@", artistInfoArray[i][@"usersRank"], artistInfoArray[i][@"numberOfFollowers" ]];
        }
    }
}


// makes height 0 of empty cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(cell == self.artist1TableViewCell && self.currentUser.detailedArtistInfoArray.count < 1)
        return 0; //set the hidden cell's height to 0
    if(cell == self.artist2TableViewCell && self.currentUser.detailedArtistInfoArray.count < 2)
        return 0; //set the hidden cell's height to 0
    if(cell == self.artist3TableViewCell && self.currentUser.detailedArtistInfoArray.count < 3)
        return 0; //set the hidden cell's height to 0
    if(cell == self.artist4TableViewCell && self.currentUser.detailedArtistInfoArray.count < 4)
        return 0; //set the hidden cell's height to 0
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

// Below two methods adds swipe left to show a delete option
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row < 4) {
        return YES;
    }
    return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // when you hit delete
        NSString *selectedArtistName = ((FNBArtist *)self.currentUser.detailedArtistInfoArray[indexPath.row]).name;
        
        // delete appropriate things from database
        [FNBFirebaseClient deleteCurrentUser:self.currentUser andArtistFromEachOthersDatabases:selectedArtistName];
        NSLog(@"you deleted %@", selectedArtistName);
        
    }
}
@end