//
//  VMMenuItem.h
//  VirtualBox Menulet
//
//  Created by Maarten Foukhar on 06-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VMMenuItem : NSMenuItem
{
	NSImage *normalIcon;
	NSImage *alternateIcon;
}

- (void)setIcon:(NSImage *)icon;
- (void)setAlternateIcon:(NSImage *)icon;

- (void)setHighlighted:(BOOL)highlight;

@end
