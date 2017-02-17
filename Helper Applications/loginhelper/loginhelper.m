//
//  loginhelper
//  Part of VirtualBox menulet
//	Created to keep compatibility with Mac OS X 10.4
//
//  Created by Maarten Foukhar on 1-7-10.
//  Copyright Kiwi Fruitware 2010 . All rights reserved.
//
//	Note: code borrowed from Growl, thanks ;-)

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	int return_code = 0;
	
	if ([args count] > 2)
	{
		NSString *argument = [args objectAtIndex:1];
		NSString *path = [args objectAtIndex:2];
	
		if ([argument isEqualTo:@"checklogin"])
		{
			LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
			Boolean    foundIt = false;
	
			//get the file url to GHA.
			CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, true);
		
			UInt32 seed = 0U;
			NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
	
			for (id itemObject in currentLoginItems) 
			{
				LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
				UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
				CFURLRef URL = NULL;
				OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			
				if (err == noErr) 
				{
					foundIt = CFEqual(URL, url);
					CFRelease(URL);
				
					if (foundIt)
						break;
				}
			}
		
			CFRelease(url);
			CFRelease(loginItems);
		
			return (int)foundIt;
		}
		else if ([argument isEqualTo:@"setlogin"] | [argument isEqualTo:@"unsetlogin"])
		{
			BOOL enabled = [argument isEqualTo:@"setlogin"];
			
			LSSharedFileListRef loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
			OSStatus status;
			CFURLRef URLToToggle = (CFURLRef)[NSURL fileURLWithPath:path];
			LSSharedFileListItemRef existingItem = NULL;

			UInt32 seed = 0U;
			NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
			for (id itemObject in currentLoginItems)
			{
				LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;

				UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
				CFURLRef URL = NULL;
				OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
				if (err == noErr)
				{
					Boolean foundIt = CFEqual(URL, URLToToggle);
					CFRelease(URL);

					if (foundIt) 
					{
						existingItem = item;
						break;
					}
				}
			}

			if (enabled && (existingItem == NULL))
			{
				NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
				IconRef icon = NULL;
				FSRef ref;
				Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
				if (gotRef)
				{
					status = GetIconRefFromFileInfo(&ref,
											/*fileNameLength*/ 0, /*fileName*/ NULL,
											kFSCatInfoNone, /*catalogInfo*/ NULL,
											kIconServicesNormalUsageFlag,
											&icon,
											/*outLabel*/ NULL);
					if (status != noErr)
						icon = NULL;
				}

				LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
			}
			else if (!enabled && (existingItem != NULL))
				LSSharedFileListItemRemove(loginItems, existingItem);
		
			CFRelease(loginItems);
		}
	}
		
	
	[pool release];

	return return_code;
}
