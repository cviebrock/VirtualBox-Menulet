//
//  VMMenuItem.m
//  VirtualBox Menulet
//
//  Created by Maarten Foukhar on 06-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "VMMenuItem.h"
#import "QuartzCore/QuartzCore.h"

@implementation VMMenuItem

- (void)dealloc
{
	if (normalIcon)
		[normalIcon release];
		
	if (alternateIcon)
		[alternateIcon release];

	[super dealloc];
}

- (void)setIcon:(NSImage *)icon
{
	if (normalIcon)
		[normalIcon release];
	
	normalIcon = [icon copy];
	[normalIcon setSize:NSMakeSize(10, 10)];
	[self setImage:icon];
}

- (void)setAlternateIcon:(NSImage *)icon
{
	if (alternateIcon)
		[alternateIcon release];
	
	alternateIcon = [icon copy];
	[alternateIcon setSize:NSMakeSize(10, 10)];
	[self setImage:icon];
}

- (void)setHighlighted:(BOOL)highlight
{
	if (normalIcon && !highlight)
		[self setImage:normalIcon];
	else if (alternateIcon && highlight)
		[self setImage:alternateIcon];
}

@end
