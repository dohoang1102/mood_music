//
//  MasterViewController.h
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ENAPI.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PinchGradientView.h"

@interface MasterViewController : UIViewController <MPMediaPickerControllerDelegate,ENAPIRequestDelegate>

@property (strong, nonatomic) IBOutlet PinchGradientView *gradientBackground;
@property (strong, nonatomic) ENAPIRequest* suggestRequest;
@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;
@property (strong, nonatomic) IBOutlet UIImageView *artworkImageView;

- (IBAction)showMediaPicker:(id)sender;
- (IBAction)volumeChanged:(id)sender;
- (IBAction)previousSong:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)nextSong:(id)sender;

- (void)registerMediaPlayerNotifications;
- (void)handleNowPlayingItemChanged:(id)notification;
- (void)handlePlaybackStateChanged:(id)notification;
- (void)getSongDataArtist:(NSString*)artist album:(NSString*)album songName:(NSString*)songName;

@end
