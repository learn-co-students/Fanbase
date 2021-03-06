//
//  FNBViewController.m
//  FanBase
//
//  Created by Mariya Eggensperger on 4/6/16.


#import "FNBDiscoverPageViewController.h"
#import "FNBCollectionViewCell.h"
#import "FNBTableViewCell.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFImageDownloader.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "FNBFirebaseClient.h"
#import <Firebase.h>
#import "FanBase-Bridging-Header.h"
#import "FanBase-Swift.h"
#import "FNBColorConstants.h"
// this is to segue to artistMainPage
#import "FNBArtistMainPageTableViewController.h"


@interface FNBDiscoverPageViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, UIScrollViewDelegate>

@property (nonatomic,strong) NSArray *imageArray;
@property (nonatomic, strong) NSArray *genres;
@property (nonatomic, strong) NSArray *genresForComparison;
@property (nonatomic, strong) NSMutableDictionary *contentOffsetDictionary;
@property (nonatomic) NSInteger section;

@property (nonatomic, strong) AFImageDownloader *imageDownloader;

@property (strong, nonatomic) NSString *selectedArtist;

@property (nonatomic, strong) NSMutableDictionary *content;

@property (nonatomic, strong) FNBUser *currentUser;
@property (nonatomic) BOOL currentUserIsLoggedIn;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UITapGestureRecognizer *dismissKeyboardTap;
@property (nonatomic) BOOL searchFieldPopulated;
@property (strong, nonatomic) NSArray *spotifyResultsArray;


@end

@implementation FNBDiscoverPageViewController


static NSInteger const minimumImageHeight = 100;


-(void)loadView
{
    [super loadView];
    
    self.imageDownloader = [AFImageDownloader defaultInstance];
    
    self.section = -1;
    const NSInteger numberOfTableViewRows = 1;
    const NSInteger numberOfCollectionViewCells = 20;
    
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:numberOfTableViewRows];
    
    for (NSInteger tableViewRow = 0; tableViewRow < numberOfTableViewRows; tableViewRow++)
    {
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:numberOfCollectionViewCells];
        
        for (NSInteger collectionViewItem = 0; collectionViewItem < numberOfCollectionViewCells; collectionViewItem++)
        {
            //don't need this yet
        }
        
        [mutableArray addObject:imageArray];
    }
    
    self.imageArray = [NSArray arrayWithArray:mutableArray];
    
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    //Gradient
//    self.view.tintColor = [UIColor colorWithRed:230.0/255.0 green:255.0/255.0 blue:247.0/255.0 alpha:1.0];
//    UIColor *gradientMaskLayer = [UIColor colorWithRed:184.0/255.0 green:204.0/255.0 blue:198.0/255.0 alpha:1.0];
//    CAGradientLayer *gradientMask = [CAGradientLayer layer];
//    gradientMask.frame = self.view.bounds;
//    gradientMask.colors = @[(id)gradientMaskLayer.CGColor,(id)[UIColor clearColor].CGColor];
//    
//    [self.view.layer insertSublayer:gradientMask atIndex:0];



    
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    


    self.selectedArtist = @"";
    
    self.searchFieldPopulated = NO;

    // start listening to if the quickAddButton pressed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTappedQuickAddButton:) name:@"userTappedQuickAddButton" object:nil];
    
    // search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
}

//// Side bar delegate method implementation
//-(void)didSelectButtonAtIndex:(NSInteger)index {
//    
//    NSLog(@"\n\nINDEX:%li", index);
//
//    if ((long)index == 0) {
//        FNBViewController *userProfileVC = [[UIStoryboard storyboardWithName:@"Firebase" bundle:nil] instantiateViewControllerWithIdentifier:@"UserPageID"];
//        // Push eventInfoVC in my window
//        [self.navigationController pushViewController:userProfileVC animated:YES];
//    } else if ((long)index == 1) {
//        FNBViewController *discoverPageVC = [[UIStoryboard storyboardWithName:@"Discover2" bundle:nil]instantiateViewControllerWithIdentifier:@"DiscoverPageID"];
//        // Push eventInfoVC in my window
//        [self.navigationController pushViewController:discoverPageVC animated:YES];
//    } else if ((long)index == 2) {
//        FNBViewController *eventsVC = [[UIStoryboard storyboardWithName:@"FNBArtistNews" bundle:nil]instantiateViewControllerWithIdentifier:@"eventInfo"];
//        // Push eventInfoVC in my window
//        [self.navigationController pushViewController:eventsVC animated:YES];
//    } 
//}
//
//// If bar menu is tapped
//-(void)hamburgerButtonTapped:(id)sender {
//    
//    if (self.sideBar.isSideBarOpen) {
//        [self.sideBar showSideBarMenu:NO];
//    } else {
//        [self.sideBar showSideBarMenu:YES];
//    }
//    
//}


-(void)hamburgerButtonTapped:(id)sender {
    NSLog(@"Hamburger pressed and posting notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HamburgerButtonNotification" object:nil];
}

// create a tapGestureRecognizer to dismiss keyboard when click out of searchBar
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    // add tap gesture for entire page to exit the search
    self.dismissKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissKeyboardTap:)];
    [self.view addGestureRecognizer:self.dismissKeyboardTap];
    
    return YES;
}
- (void) handleDismissKeyboardTap:(UITapGestureRecognizer *)recognizer {
    NSLog(@"anywhere tapped");
    [self.searchBar resignFirstResponder];

}
-(BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    [self.view removeGestureRecognizer:self.dismissKeyboardTap];
    return YES;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.searchFieldPopulated = YES;
    [FNBSpotifySearch getArrayOfMatchingArtistsFromSearch:searchBar.text withCompletionBlock:^(BOOL gotMatchingArtists, NSArray *matchingArtistsArray) {
    
        FNBTableViewCell *collectionViewCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
       [collectionViewCell.collectionView setContentOffset:CGPointZero animated:NO];
        
        if (gotMatchingArtists) {
            self.spotifyResultsArray = matchingArtistsArray;
            [self.tableView reloadData];

        }
        else {
            NSLog(@"Did not get any matching artist from Spotify for your search: %@", searchBar.text);
        }
    }];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if (self.searchFieldPopulated && searchBar.text.length == 0) {
        self.searchFieldPopulated = NO;
        [self.tableView reloadData];
    }
}

-(BOOL)array:(NSArray *)array caseInsensitiveContainsString:(NSString *)string
{
    for(NSString *arrayString in array) {
        if([arrayString localizedCaseInsensitiveContainsString:string]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    

    //find if user is logged in, if so, get their subscribed users
    self.currentUser = [[FNBUser alloc] init];
    [FNBFirebaseClient checkOnceIfUserIsAuthenticatedWithCompletionBlock:^(BOOL isAuthenticUser) {
        if (isAuthenticUser) {
            NSLog(@"user is logged in");
            self.currentUserIsLoggedIn = YES;

                //Initializes hamburger bar menu button
                UIBarButtonItem *hamburgerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleDone target:self action:@selector(hamburgerButtonTapped:)];
                self.navigationItem.rightBarButtonItem = hamburgerButton;
            // set properties of user from Firebase
            [FNBFirebaseClient setPropertiesOfLoggedInUserToUser:self.currentUser withCompletionBlock:^(BOOL completedSettingUsersProperties) {
                if (completedSettingUsersProperties) {
                    NSLog(@"done setting user properties in Discover Page");
                    
                    // not sure if this is necessary
                    //                    [self.tableView reloadData];
                }
                else {
                    NSLog(@"There was an error setting user properties in Discover Page");
                }
            }];
        }
        // if not an Authentic User
        else {
            NSLog(@"user is a guest (not logged in)");
            self.currentUserIsLoggedIn = NO;
        }
    }];
    
    
    self.content = [NSMutableDictionary new];
    
    self.genres = @[@"Pop", @"Hip Hop", @"Country", @"EDM/Dance", @"Rock", @"Latino", @"Soul", @"Folk & American", @"Jazz", @"Classical", @"Comedy", @"Metal", @"K-Pop", @"Reggae", @"Punk", @"Funk", @"Blues"];
    [self.genres sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    
    //Calls on data in firebase
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://fanbaseflatiron.firebaseio.com/artists"];
    
    //NSLog(@"%llu", dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)));
    
    // Block reads artist data in firebase
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        
        // seems like repeated access of snapshot.value is painfully slow.
        // so... we're going to stash it in a variable and use that instead.
        NSDictionary *snapshotValue = snapshot.value;
        
            //Compiles a dictionary in specific format
            for (NSString *artistName in snapshotValue) {
                
                NSDictionary *artistInfo = snapshotValue[artistName];
                NSArray *images = artistInfo[@"images"];
                
                // get smallest image that is minimum height
                NSMutableDictionary *selectedImage = [NSMutableDictionary new];
                for (NSDictionary *imageDescription in images) {
                    if ([imageDescription[@"height"] integerValue] > minimumImageHeight) {
                        selectedImage = [imageDescription mutableCopy];
                    }
                }
                NSString *imageURL = selectedImage[@"url"];
//                NSDictionary *firstImage = images.firstObject;
//                NSString *imageURL = firstImage[@"url"];
                NSString *spotifyID = artistInfo[@"spotifyID"];
                NSArray *genres = artistInfo[@"genres"];
                
                NSString *artistGenre;
                for (NSString *genre in genres) {
                    NSPredicate *genrePredicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", genre];
                    NSArray *filteredGenres = [self.genres filteredArrayUsingPredicate:genrePredicate];
                    if (filteredGenres.count > 0) {
                        artistGenre = filteredGenres[0];
                        break;
                    }
                }
                
//                NSLog(@"\n\nartistName: %@\nimageURL: %@\nartistGenre: %@\n\n",artistName,imageURL, artistGenre);
                
                if (artistGenre != nil) {
                    if ([self.content objectForKey:artistGenre]) {
                        
                        NSMutableArray *contentObjects = self.content[artistGenre];
                        NSMutableArray *artistNames = contentObjects[0];
                        NSMutableDictionary *artistNameAndImageURL = contentObjects[1];
                        
                        
                        NSMutableDictionary *artistNameAndSpotifyID = contentObjects[2];
                        
                        [artistNameAndImageURL setValue:imageURL forKey:artistName];
                        
                        
                        [artistNameAndSpotifyID setValue:spotifyID forKey:artistName];
                        
                        [artistNames addObject:artistName];
//                        NSLog(@"\n\nself.content artistName: %@\n\n",artistName);
                        
                    } else {
                        
                        NSMutableArray *contentObjects = [NSMutableArray new];
                        NSMutableArray *artistNames = [NSMutableArray new];
                        NSMutableDictionary *artistNameAndImageURL = [NSMutableDictionary new];
                        
                        NSMutableDictionary *artistNameAndSpotifyID = [NSMutableDictionary new];
                        
                        [artistNameAndImageURL setValue:imageURL forKey:artistName];
                        
                        
                        [artistNameAndSpotifyID setValue:spotifyID forKey:artistName];
                        
                        [artistNames addObject:artistName];
//                        NSLog(@"\n\nFIRST TIME\nself.content artistName: %@\n\n",artistName);
                        
                        [contentObjects addObject:artistNames];
                        [contentObjects addObject:artistNameAndImageURL];
                        
                        
                        [contentObjects addObject:artistNameAndSpotifyID];
                        
                        [self.content setObject:contentObjects forKey:artistGenre];
                        
                        }
                    }
                
            }
        
//        NSLog(@"end");
        
//        NSLog(@"about to reloadtdata");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
//            [self.view bringSubviewToFront:self.sideBar.sideBarContainerView];
            
//            NSLog(@"%llu", dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)));
        }];
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"Error in discoverPage: %@", error.description);
    }];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // for search results
    if (self.searchFieldPopulated) {
        return 1;
    }
    
    // Count all keys (genres) in content dictionary
    // to establish number of sections needed in tableview
    return self.genres.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    // for search results
    if (self.searchFieldPopulated) {
        return @"Search Result";
    }
    
    if (self.genres.count > 0) {
        return self.genres[section];
    }
    
    return @"";
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    NSLog(@"\n\n\nTableView cell: %li\n\n\n",indexPath.row);
    static NSString *CellIdentifier = @"CellIdentifier";
    
    FNBTableViewCell *cell = (FNBTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    
    if (!cell)
    {
        cell = [[FNBTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.backgroundView.backgroundColor = FNBLightGreenColor;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(FNBTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
    NSInteger index = cell.collectionView.tag;
    
    CGFloat horizontalOffset = [self.contentOffsetDictionary[[@(index) stringValue]] floatValue];
    [cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0) animated:NO];
    
    [cell.collectionView registerClass:[FNBCollectionViewCell class] forCellWithReuseIdentifier:CollectionViewCellIdentifier];
    
    cell.collectionView.backgroundColor = [UIColor clearColor];
}

#pragma mark - UITableViewDelegate Methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *tappedTableViewCell = (UITableViewCell *)collectionView.superview.superview;
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:tappedTableViewCell];
    
    // for search results
    if (self.searchFieldPopulated) {
        NSString *artistNameFromSearch = self.spotifyResultsArray[indexPath.row][@"name"];
        NSLog(@"you selected %@", artistNameFromSearch);
        // create a firebase entry 
        [FNBFirebaseClient makeDatabaseEntryForArtistFromSpotifyDictionary: self.spotifyResultsArray[indexPath.row] withCompletionBlock:^(BOOL artistDatabaseCreated) {
            if (artistDatabaseCreated) {
                NSLog(@"Successfully made Firebase databse for searched artist: %@", artistNameFromSearch);
                self.selectedArtist = artistNameFromSearch;
                // only perform segue if artistName is loaded
                if (artistNameFromSearch.length > 0) {
                    [self performSegueWithIdentifier:@"discoverPageSegue" sender:self];
                }
                else {
                    NSLog(@"SEGUE NOT HAPPENING CUS ARTIST IS NIL");
                }

            }
            else {
                NSLog(@"couldnt make Firebase database entry for searched artist: %@", artistNameFromSearch);
            }
            
            
        }];
    }
    else {
        NSInteger tableViewSection = selectedIndexPath.section;
        NSString *genre = self.genres[tableViewSection];
        NSArray *artistContent = self.content[genre];
        NSArray *artistNames = artistContent[0];
        NSString *artistName = artistNames[indexPath.item];
        //    NSLog(@"this is the section %li ", selectedIndexPath.section);
        NSLog(@"you selected: %@", artistName);
        self.selectedArtist = artistName;
        
        // only perform segue if artistName is loaded
        if (artistName.length > 0) {
            [self performSegueWithIdentifier:@"discoverPageSegue" sender:self];
        }
        else {
            NSLog(@"SEGUE NOT HAPPENING CUS ARTIST IS NIL");
        }
    }
    
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
}


#pragma mark - UICollectionViewDataSource Methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // for search results
    if (self.searchFieldPopulated) {
        return self.spotifyResultsArray.count;
    }

//    NSLog(@"\n\n\nCollectionView section: %li\n\n\n",section);
    UIView *view = [collectionView superview];
    FNBTableViewCell *cell = (FNBTableViewCell *)[view superview];
    NSIndexPath *ip = [self.tableView indexPathForCell:cell];
    NSInteger tableViewSection = ip.section;
    NSString *genre = self.genres[tableViewSection];
    NSArray *artistContent = self.content[genre];
    NSArray *artistNames = artistContent[0];
    
    return artistNames.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    FNBCollectionViewCell *cell = (FNBCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor clearColor];
    
    // for search results
    if (self.searchFieldPopulated) {
//        [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
//        NSLog(@"Search field populated");
        NSString *artistNameFromSpotify = self.spotifyResultsArray[indexPath.row][@"name"];
        
        cell.artist = artistNameFromSpotify;
        cell.artistSpotifyID = self.spotifyResultsArray[indexPath.row][@"id"];
        cell.image = nil;
        [cell.quickAddButton removeFromSuperview];
        cell.isUserLoggedIn = self.currentUserIsLoggedIn;
        cell.isUserSubscribedToArtist = [self isUserSubscribedToArtistName:artistNameFromSpotify];
        
        // if they have an image
        if (((NSArray *)self.spotifyResultsArray[indexPath.row][@"images"]).count > 0) {
            NSString *artistImageURLFromSpotify = self.spotifyResultsArray[indexPath.row][@"images"][0][@"url"];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:artistImageURLFromSpotify]];
            [self.imageDownloader downloadImageForURLRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject) {
                // need to double-check that this cell is still supposed to be showing the image for the artist we just received.
                // if cells are reused, this check will fail.
                if([cell.artist isEqualToString:artistNameFromSpotify]) {
                    cell.image = responseObject;
                }
            } failure:nil];
            
            cell.clipsToBounds = YES;

        }
        
    }
    else {
//        NSLog(@"Search field NOT populated");

        UIView *view = [collectionView superview];
        FNBTableViewCell *tableViewCell = (FNBTableViewCell *)[view superview];
        tableViewCell.backgroundColor = [UIColor clearColor];
        
        NSIndexPath *ip = [self.tableView indexPathForCell:tableViewCell];
        NSInteger tableViewSection = ip.section;
        NSString *genre = self.genres[tableViewSection];
        NSArray *artistContent = self.content[genre];
        NSArray *artistNames = artistContent[0];
        NSString *artistName = artistNames[indexPath.item];
        cell.artist = artistName;
        
        NSDictionary *artistImages = artistContent[1];
        NSString *artistImageURL = artistImages[artistName];
        //    NSLog(@"this is the artist URL: %@", artistImageURL);
        
        cell.image = nil;
        
        NSDictionary *artistSpotifyIDs = artistContent[2];
        NSString *spotifyIDOfArtist = artistSpotifyIDs[artistName];
        cell.artistSpotifyID = spotifyIDOfArtist;
        
        
        // this stops the quickAddButton images from overlapping
        [cell.quickAddButton removeFromSuperview];
        // this is for the quickAddButton
        cell.isUserLoggedIn = self.currentUserIsLoggedIn;
        //    cell.isUserSubscribedToArtist = NO;
        cell.isUserSubscribedToArtist = [self isUserSubscribedToArtistName:artistName];
        
        
        
        
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:artistImageURL]];
        [self.imageDownloader downloadImageForURLRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *responseObject) {
            // need to double-check that this cell is still supposed to be showing the image for the artist we just received.
            // if cells are reused, this check will fail.
            if([cell.artist isEqualToString:artistName]) {
                cell.image = responseObject;
            }
        } failure:nil];
        
        cell.clipsToBounds = YES;
    }
    
    return cell;
    
}

#pragma mark - UIScrollViewDelegate Methods

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![scrollView isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    scrollView.backgroundColor = [UIColor clearColor];
    
    CGFloat horizontalOffset = scrollView.contentOffset.x;
    
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    NSInteger index = collectionView.tag;
    self.contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
    
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    UINavigationController *nextNavController = [segue destinationViewController];
//    FNBArtistMainPageTableViewController *nextVC = [nextNavController viewControllers][0];
//    nextVC.receivedArtistName = self.selectedArtist;
    
    // dont allow sending nil
    if (self.selectedArtist) {
        FNBArtistMainPageTableViewController *nextVC = segue.destinationViewController;
        nextVC.receivedArtistName = self.selectedArtist;
    }
    else {
        NSLog(@"the selectedArtist property is nil ");
    }

}

- (BOOL) isUserSubscribedToArtistName:(NSString *)artistName {
    // if the currentUser has received the subscribedArtist dictionary from Firebase
    if (self.currentUser.artistsDictionary.count > 0) {
        for (NSString *artistNameInUserDictionary in self.currentUser.artistsDictionary) {
            if ([artistNameInUserDictionary isEqualToString:artistName]) {
                return YES;
            }
        }
        return NO;
    }
    else {
        NSLog(@"Nothing int he user dictionary!");
        // need this line to compile
        return NO;
    }
}
- (void) userTappedQuickAddButton:(NSNotification *)notification {
    NSString *nameOfArtistFromCell = [notification object][0];
    NSString *spotifyIDOfArtistFromCell = [notification object][1];
    NSLog(@"In discover page, received artist name: %@, and the spotifyID: %@", nameOfArtistFromCell, spotifyIDOfArtistFromCell);
    
    // if the user is subscribed to this artist, then delete. If the user isn't subscribe, then add
    if ([self isUserSubscribedToArtistName:nameOfArtistFromCell]) {
        [FNBFirebaseClient deleteCurrentUser:self.currentUser andArtistFromEachOthersDatabases:nameOfArtistFromCell withCompletionBlock:^(BOOL deletedArtistAndUserCompleted) {
            if (deletedArtistAndUserCompleted) {
                NSLog(@"You have deleted artist %@ from the Discover Page", nameOfArtistFromCell);
                // refresh the user
                [FNBFirebaseClient setPropertiesOfLoggedInUserToUser:self.currentUser withCompletionBlock:^(BOOL completedSettingUsersProperties) {
                    // make this reload just the cell
                    [self.tableView reloadData];

                }];
            }
        }];
    }
    else {
        [FNBFirebaseClient addUser:self.currentUser andArtistWithSpotifyID:spotifyIDOfArtistFromCell toDatabaseWithCompletionBlock:^(BOOL artistAddedToUserSuccessfully) {
            if (artistAddedToUserSuccessfully) {
                NSLog(@"added artist %@ and user using spotifyID", nameOfArtistFromCell);
                
                // refresh the user
                [FNBFirebaseClient setPropertiesOfLoggedInUserToUser:self.currentUser withCompletionBlock:^(BOOL completedSettingUsersProperties) {
                    // make this reload just the cell
                    [self.tableView reloadData];

                }];
                
            }
        }];
        
    }
}

@end
