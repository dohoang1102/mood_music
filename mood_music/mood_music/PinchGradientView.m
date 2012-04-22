//
//  PinchGradientView.m
//  mood_music
//
//  Created by andrew batutin on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PinchGradientView.h"

@implementation PinchGradientView

@synthesize pitchData;
@synthesize recivedData;
@synthesize connection;

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
		id obj = [[[SBJsonParser alloc] init] objectWithData:recivedData];
		NSArray* arr = [obj valueForKey:@"segments"];
		NSMutableArray* buffer = [NSMutableArray array];
		for (id seg in arr)
		{
			[buffer addObject:[seg valueForKey:@"pitches"]];
		}
		pitchData = [NSArray arrayWithArray:buffer];
		recivedData = nil;
	}
	connection = nil;
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{
	NSLog(@"Failed to load data at %@, %@", theConnection, [error localizedDescription]);
	connection = nil;
	recivedData = nil;
}

#pragma mark - Public methods

- (void)cancelLoading
{
	[connection cancel];
	connection = nil;
	recivedData = nil;
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

-(CGColorRef)pitchToColorHsb:(NSNumber*)pitch
{
	return [[UIColor colorWithHue:[pitch floatValue] saturation:[pitch floatValue] brightness:[pitch floatValue] alpha:1] CGColor];
}

- (CGColorRef)pitchToColorRgb:(NSNumber*)pitch
{
	return [[UIColor colorWithRed:[pitch floatValue] green:[pitch floatValue] blue:[pitch floatValue] alpha:1] CGColor];
}

@end
