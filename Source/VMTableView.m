//
//  VMTableView.m
//  VirtualBox Menulet
//
//  Created by Maarten Foukhar on 23-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "VMTableView.h"


@implementation VMTableView

- (void)keyDown:(NSEvent *)theEvent
{
	if (NSCommandKeyMask & [theEvent modifierFlags])
	{
		if ([theEvent keyCode] == 0)
		{
			[self selectAll:nil];
			return;
		}
	}
	
	[super keyDown:theEvent];
}

@end
