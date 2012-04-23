//
//  MasterViewController.m
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"

@implementation MasterViewController

@synthesize musicPlayer;
@synthesize volumeSlider;
@synthesize playPauseButton;
@synthesize artworkImageView;
@synthesize gradientBackground;
@synthesize suggestRequest;

#pragma mark - Memory management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
												  object: musicPlayer];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
												  object: musicPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerVolumeDidChangeNotification
												  object: musicPlayer];
    
	[musicPlayer endGeneratingPlaybackNotifications];
	[gradientBackground cancelLoading];
	[suggestRequest cancel];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
												  object: musicPlayer];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
												  object: musicPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerVolumeDidChangeNotification
												  object: musicPlayer];
    
	[musicPlayer endGeneratingPlaybackNotifications];

	[self setVolumeSlider:nil];
	[self setPlayPauseButton:nil];
	[self setArtworkImageView:nil];
	[self setGradientBackground:nil];
	
	[gradientBackground cancelLoading];
	[suggestRequest cancel];

    [super viewDidUnload];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showMediaPicker:)];
	self.navigationItem.leftBarButtonItem = addButton;
	
	musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    [volumeSlider setValue:[musicPlayer volume]];
	[musicPlayer setRepeatMode:MPMusicRepeatModeAll];
	if ([musicPlayer playbackState] == MPMusicPlaybackStatePlaying)
        [playPauseButton setImage:[UIImage imageNamed:@"pauseButton.png"] forState:UIControlStateNormal];
	else
        [playPauseButton setImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
	
    [self registerMediaPlayerNotifications];
	[gradientBackground setMusicPlayer:musicPlayer];
}

#pragma mark - IBActions

- (IBAction)volumeChanged:(id)sender 
{
    [musicPlayer setVolume:[volumeSlider value]];
}

- (IBAction)previousSong:(id)sender 
{
	[musicPlayer skipToPreviousItem];
}

- (IBAction)playPause:(id)sender 
{
    if ([musicPlayer playbackState] == MPMusicPlaybackStatePlaying)
        [musicPlayer pause];
	else 
        [musicPlayer play];
}

- (IBAction)nextSong:(id)sender 
{
	[musicPlayer skipToNextItem];
}

#pragma mark - Notifications

- (void)registerMediaPlayerNotifications 
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
	[notificationCenter addObserver: self
						   selector: @selector (handleNowPlayingItemChanged:)
							   name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
							 object: musicPlayer];
	
	[notificationCenter addObserver: self
						   selector: @selector (handlePlaybackStateChanged:)
							   name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
							 object: musicPlayer];
    
    [notificationCenter addObserver: self
						   selector: @selector (handleVolumeChanged:)
							   name: MPMusicPlayerControllerVolumeDidChangeNotification
							 object: musicPlayer];
    
	[musicPlayer beginGeneratingPlaybackNotifications];
}


- (void)handleNowPlayingItemChanged:(id)notification
{
   	MPMediaItem *currentItem = [musicPlayer nowPlayingItem];
	UIImage *artworkImage = [UIImage imageNamed:@"noArtworkImage.png"];
	MPMediaItemArtwork *artwork = [currentItem valueForProperty: MPMediaItemPropertyArtwork];
	if (artwork) 
		artworkImage = [artwork imageWithSize:CGSizeMake (200, 200)];
    [artworkImageView setImage:artworkImage];
    
    NSString *titleString = [currentItem valueForProperty:MPMediaItemPropertyTitle];
    NSString *artistString = [currentItem valueForProperty:MPMediaItemPropertyArtist];
    NSString *albumString = [currentItem valueForProperty:MPMediaItemPropertyAlbumTitle];

	self.navigationItem.title = [NSString stringWithFormat:@"%@ %@",artistString, titleString];
	[self getSongDataArtist:artistString album:albumString songName:titleString];
}

- (void)handlePlaybackStateChanged:(id)notification 
{
    MPMusicPlaybackState playbackState = [musicPlayer playbackState];
	
	if (playbackState == MPMusicPlaybackStatePaused) 
        [playPauseButton setImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
	else if (playbackState == MPMusicPlaybackStatePlaying) 
        [playPauseButton setImage:[UIImage imageNamed:@"pauseButton.png"] forState:UIControlStateNormal];
	else if (playbackState == MPMusicPlaybackStateStopped) 
	{
        [playPauseButton setImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
		[musicPlayer stop];
	}
}

- (void)handleVolumeChanged:(id)notification 
{
    [volumeSlider setValue:[musicPlayer volume]];
}

#pragma mark - Media Picker

- (IBAction)showMediaPicker:(id)sender
{
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAny];
	mediaPicker.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = YES;
    mediaPicker.prompt = @"Select songs to play";
    
    [self presentModalViewController:mediaPicker animated:YES];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *) mediaItemCollection
{
    if (mediaItemCollection) 
	{
		[musicPlayer setQueueWithItemCollection:mediaItemCollection];
        [musicPlayer play];
    }
	[self dismissModalViewControllerAnimated: YES];
}


- (void)mediaPickerDidCancel:(MPMediaPickerController*) mediaPicker 
{
	[self dismissModalViewControllerAnimated: YES];
}

#pragma mark - ENAPIRequestDelegate

- (void)requestFinished:(ENAPIRequest *)request 
{
	// The Echo Nest server has repsonded. 
	// There are handy accessors for the Echo Nest status
	// code and status message
	NSLog(@"echonestStatusMessage %@, %@", request, request.echonestStatusMessage);
    NSArray *songs = [request.response valueForKeyPath:@"response.songs"];
	NSString* detailDataUrl = [[songs lastObject] valueForKeyPath:@"audio_summary.analysis_url"];
	[gradientBackground loadDataAtURL:[NSURL URLWithString:detailDataUrl]];
}

- (void)requestFailed:(ENAPIRequest *)request 
{
    // The request or connection failed at a low level, use
	// the request's error property to get information on the
	// failure
	NSLog(@"Failed to load at %@, %@", request, [request.error localizedDescription]);
}

#pragma mark - Private methods

// start ENAPIRequest to get the data abot the song
- (void)getSongDataArtist:(NSString*)artist album:(NSString*)album songName:(NSString*)songName
{
	// ask the Echo Nest server for suggestions
	[gradientBackground cancelLoading];
	[suggestRequest cancel];
	suggestRequest = [[ENAPIRequest alloc] initWithEndpoint:@"song/search"];
	[suggestRequest setValue:@"1" forParameter:@"results"];
	[suggestRequest setValue:@"audio_summary" forParameter:@"bucket"];
	suggestRequest.delegate = self;
    [suggestRequest setValue:artist forParameter:@"artist"];
	[suggestRequest setValue:songName forParameter:@"title"];
    [suggestRequest startAsynchronous];
}


@end
