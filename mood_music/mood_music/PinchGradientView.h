//
//  PinchGradientView.h
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// used to show track pinc as gradient
#import <UIKit/UIKit.h>
#import "SBJsonParser.h"

@interface PinchGradientView : UIView <NSURLConnectionDelegate>

@property(nonatomic,strong) NSArray* pitchData;
@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSMutableData* recivedData;

- (void)loadDataAtURL:(NSURL *)url;
- (void)cancelLoading;
- (CGColorRef)pitchToColorHsb:(NSNumber*)pitch;
- (CGColorRef)pitchToColorRgb:(NSNumber*)pitch;

@end
