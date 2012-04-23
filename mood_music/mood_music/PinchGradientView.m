//
//  PinchGradientView.m
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinchGradientView.h"

#define ANIMATION_DURATION 2.f

@implementation PinchGradientView

@synthesize animationIndex;
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
		animationIndex = 0;
        animationTimer = [NSTimer scheduledTimerWithTimeInterval:ANIMATION_DURATION target:self selector:@selector(performGradientAnimationFromIndex) userInfo:nil repeats:YES];
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
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	// schedule at run loop so any ui event won't prevent the erquest to start
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[connection start];
}

#pragma mark - Private methods

- (void)animFrom:(NSArray*)arrayColorFrom animto:(NSArray*)arrayColorTo
{
    CAGradientLayer *gLayer = (CAGradientLayer *)self.layer;
    gLayer.colors = arrayColorTo;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"colors"];
    anim.fromValue = arrayColorFrom;
    anim.duration = ANIMATION_DURATION;
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
			animationIndex = 0;
            pitchData = [NSArray arrayWithArray:buffer];
        });
    });
}

- (void)performGradientAnimationFromIndex
{
	if( pitchData.count > 0 )
	{
		if( animationIndex > pitchData.count - 1 )
			animationIndex = 0;
		NSArray* colorBufferFrom = [(NSDictionary*)[pitchData objectAtIndex:animationIndex] objectForKey:@"colorBuffer"];
		NSArray* colorBufferTo = [(NSDictionary*)[pitchData objectAtIndex:++animationIndex] objectForKey:@"colorBuffer"];
		[self animFrom:colorBufferFrom animto:colorBufferTo];
	}
}

@end
