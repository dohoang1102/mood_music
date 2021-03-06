//
//  PinchGradientView.h
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// used to show song pinch as gradient

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SBJsonParser.h"

@interface PinchGradientView : UIView <NSURLConnectionDelegate>

@property (nonatomic, strong) MPMusicPlayerController *musicPlayer;
@property(nonatomic,strong) NSTimer* animationTimer;
@property(nonatomic,strong) NSArray* pitchData;
@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSMutableData* recivedData;

- (void)loadDataAtURL:(NSURL *)url;
- (void)cancelLoading;
- (void)sortSongData;
- (void)animFrom:(NSArray*)arrayColorFrom animTo:(NSArray*)arrayColorTo withDuration:(NSNumber*)duration;
- (id)pitchToColorHsb:(NSNumber*)pitch;
- (id)pitchToColorRgb:(NSNumber*)pitch;
- (void)performGradientAnimationFromIndex;

@end
