//
//  PCOAnnouncerController.m
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAnnouncerController.h"

#import "JSONKit.h"

#import "RKXMLParserLibXML.h"

@implementation PCOAnnouncerController

@synthesize logoUrl, announcements, flickrImageUrls;

- (id)init;
{
	self = [super init];
	if (self)
	{
		PCOAnnouncerMainTableViewController * mainTableController = [[PCOAnnouncerMainTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		
		mainNavigationController = [[UINavigationController alloc] initWithRootViewController:mainTableController];
		
		
	}
	
	return self;
}

+ (NSString *)localCacheDirectoryPath;
{
	NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	return path;
}

- (UIViewController *)viewController;
{
	return mainNavigationController;
}


- (void)downloadImageFromUrl:(NSString *)imageUrl withCompletionBlock:(void (^)(void))completionBlock andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.imagedownloads", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
		
		NSData* imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		if (!imageData)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSLog(@"saving to %@", [self pathForImageFileAtUrl:imageUrl]);
		
		if (![imageData writeToFile:[self pathForImageFileAtUrl:imageUrl] atomically:YES])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Unable to save image file" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				completionBlock();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
		}
		
	});
	
	
}


- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;
{
	return [[PCOAnnouncerController localCacheDirectoryPath] stringByAppendingPathComponent:[imageUrl lastPathComponent]];
}


- (void)loadAnnouncementsFromFeedLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:feedUrl]];
		
		NSData* jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			
			return;
		}
		
		if (!jsonData)
		{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSDictionary *resultsDictionary = [jsonData objectFromJSONData];
		
		if ([resultsDictionary objectForKey:@"logo_image_url"])
		{
			logoUrl = [[resultsDictionary objectForKey:@"logo_image_url"] copy];
			NSLog(@"loading logo from %@", logoUrl);
			
			[self downloadImageFromUrl:logoUrl withCompletionBlock:^{
				
				NSLog(@"downloaded image");
				
			} andErrorBlock:^(NSError * error) {
				
				NSLog(@"error loading image: %@", [error localizedDescription]);
				
			}];
		}
		
		if ([resultsDictionary objectForKey:@"announcements"])
		{
			announcements = [[resultsDictionary objectForKey:@"announcements"] copy];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				completion();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"No announcements" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
	});
	
}


- (void)loadFlickrFeedFromLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:feedUrl]];
		
		NSData* jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		if (!jsonData)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		
		RKXMLParserLibXML * parser = [[RKXMLParserLibXML alloc] init];
		
		NSDictionary *resultsDictionary = [parser parseXML:jsonString];
		
		/*
		 if ([resultsDictionary objectForKey:@"announcements"])
		 {
		 announcements = [[resultsDictionary objectForKey:@"announcements"] copy];
		 
		 completion();
		 }
		 else
		 {
		 errorBlock([NSError errorWithDomain:@"No announcements" code:0 userInfo:nil]);
		 }
		 */
		
		if (!resultsDictionary)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid XML" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSMutableArray * newImageUrls = [NSMutableArray array];
		
		if ([[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"])
		{
			//NSLog(@"items: %@", NSStringFromClass([[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"]));
			
			//NSLog(@"object count: %lu", [[[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"] count]);
			
			for (NSDictionary * item in [[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"])
			{
				//NSLog(@"item content: %@", [[item objectForKey:@"content"] objectForKey:@"url"]);
				
				[newImageUrls addObject:[[item objectForKey:@"content"] objectForKey:@"url"]];
				
				[self downloadImageFromUrl:[[item objectForKey:@"content"] objectForKey:@"url"] withCompletionBlock:^{
					NSLog(@"image downloaded");
				} andErrorBlock:^(NSError * error) {
					NSLog(@"error loading image: %@", [error localizedDescription]);
				}];
			}
			
			if ([newImageUrls count] > 0)
			{
				flickrImageUrls = newImageUrls;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				completion();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid feed" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		
		//NSLog(@"results: %@", resultsDictionary);
		
	});
	
}


@end
