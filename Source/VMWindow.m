//
//  VMWindow.m
//  VirtualBox Menulet
//
//  Created by Maarten Foukhar on 23-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "VMWindow.h"


@implementation VMWindow

- (void)keyDown:(NSEvent *)theEvent
{
	if (NSCommandKeyMask & [theEvent modifierFlags])
	{
		if ([theEvent keyCode] == 13)
		{
			[self orderOut:nil];
			return;
		}
		else if ([theEvent keyCode] == 46)
		{
			[self miniaturize:nil];
			return;
		}
	}
	
	[super keyDown:theEvent];
}

@end
