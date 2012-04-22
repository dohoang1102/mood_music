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
#import "SBJsonParser.h"

@interface PinchGradientView : UIView <NSURLConnectionDelegate>

@property(nonatomic,readwrite) NSInteger animationIndex;
@property(nonatomic,strong) NSTimer* animationTimer;
@property(nonatomic,strong) NSArray* pitchData;
@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSMutableData* recivedData;

- (void)loadDataAtURL:(NSURL *)url;
- (void)cancelLoading;
- (void)sortSongData;
- (void)animFrom:(NSArray*)arrayColorFrom animto:(NSArray*)arrayColorTo;
- (id)pitchToColorHsb:(NSNumber*)pitch;
- (id)pitchToColorRgb:(NSNumber*)pitch;
- (void)performGradientAnimationFromIndex;

@end
