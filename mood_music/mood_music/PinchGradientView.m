//
//  PinchGradientView.m
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinchGradientView.h"

#define UPDATE_DURATION 1.f

@implementation PinchGradientView

@synthesize musicPlayer;
@synthesize pitchData;
@synthesize recivedData;
@synthesize connection;
@synthesize animationTimer;

+ (Class)layerClass 
{
    return [CAGradientLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
    if (self) 
	{
        animationTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_DURATION target:self selector:@selector(performGradientAnimationFromIndex) userInfo:nil repeats:YES];
    }
    return self;

}

#pragma mark - Memory management

- (void)dealloc
{
	[connection cancel];
	[self setConnection:nil];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// every time we get an response it might be a forward, so we discard what data we have
	recivedData = nil;
	recivedData = [[NSMutableData alloc] init];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[recivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
	if (recivedData)
	{
        [self sortSongData];
		recivedData = nil;
	}
	connection = nil;
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{
	NSLog(@"Failed to load data at %@, %@", theConnection, [error localizedDescription]);
	connection = nil;
	recivedData = nil;
	pitchData = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Public methods

- (void)cancelLoading
{
	[connection cancel];
	connection = nil;
	recivedData = nil;
	pitchData = nil;
}

- (void)loadDataAtURL:(NSURL *)url
{
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
	[connection cancel];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - Private methods

- (void)animFrom:(NSArray*)arrayColorFrom animTo:(NSArray*)arrayColorTo withDuration:(NSNumber*)duration
{
    CAGradientLayer *gLayer = (CAGradientLayer *)self.layer;
	NSArray* prevColor = gLayer.colors;
    gLayer.colors = arrayColorTo;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"colors"];
    anim.fromValue = prevColor;
    anim.duration = [duration floatValue];
	anim.toValue = arrayColorTo;
    anim.timingFunction = [CAMediaTimingFunction 
                           functionWithName:kCAMediaTimingFunctionEaseOut];
    [gLayer addAnimation:anim forKey:@"colors"];
}

-(id)pitchToColorHsb:(NSNumber*) pitch
{
	return (id)[[UIColor colorWithHue:[pitch floatValue] saturation:[pitch floatValue] brightness:[pitch floatValue] alpha:1] CGColor];
}

- (id)pitchToColorRgb:(NSNumber*) pitch
{
	return (id)[[UIColor colorWithRed:[pitch floatValue] green:[pitch floatValue] blue:[pitch floatValue] alpha:1] CGColor];
}

// parse resp from server and extract pinch data
- (void)sortSongData
{
    // it take some time to sort data - so we put it to global queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__block NSData* data = recivedData;
	__block id blockSelf = self;
    dispatch_async( queue, ^{
        id obj = [[[SBJsonParser alloc] init] objectWithData:data];
        NSArray* arr = [obj valueForKey:@"segments"];
        NSMutableArray* buffer = [NSMutableArray array];
        for (id seg in arr)
        {
            NSArray* pitches =[seg valueForKey:@"pitches"];
			NSMutableArray* colorBuffer = [NSMutableArray array];
			NSMutableDictionary* dict = [NSMutableDictionary dictionary];
			for(NSNumber* pitch in pitches)
			{
				[colorBuffer addObject:[blockSelf pitchToColorHsb:pitch]];
			}
			[dict setObject:colorBuffer forKey:@"colorBuffer"];
			[dict setObject:[seg valueForKey:@"start"] forKey:@"start"];
			[dict setObject:[seg valueForKey:@"duration"] forKey:@"duration"];
			[buffer addObject:dict];
        }
        
        // on main thread set data arrays
        dispatch_async(dispatch_get_main_queue(), ^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            pitchData = [NSArray arrayWithArray:buffer];
        });
    });
}

- (void)performGradientAnimationFromIndex
{
	if( pitchData.count > 0 )
	{

		NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"start >= %f AND start <= %f", (float)musicPlayer.currentPlaybackTime, (float)musicPlayer.currentPlaybackTime + 2.f]];
		NSMutableArray* currentPinch = [NSMutableArray arrayWithArray:pitchData];
		[currentPinch filterUsingPredicate:predicate];
		if (currentPinch.count > 1)
		{
			NSArray* colorBufferFrom = [(NSDictionary*)[currentPinch objectAtIndex:0] objectForKey:@"colorBuffer"];
			NSArray* colorBufferTo = [(NSDictionary*)[currentPinch objectAtIndex:1] objectForKey:@"colorBuffer"];
			[self animFrom:colorBufferFrom animTo:colorBufferTo withDuration:[NSNumber numberWithFloat:UPDATE_DURATION]];
		}
	}
}

@end
