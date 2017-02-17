//
//  VMCrippledButton.m
//  A button that does nothing, just being pretty :-)
//  Sub-classed cell thanks to: http://www.mikeash.com/pyblog/custom-nscells-done-right.html
//
//  Created by Maarten Foukhar on 27-06-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "VMCrippledButton.h"

@implementation VMCrippledButton

- initWithCoder:(NSCoder *)origCoder
{
	NSKeyedUnarchiver *coder = (id)origCoder;
		
	// gather info about the superclass's cell and save the archiver's old mapping
	Class superCell = [[self superclass] cellClass];
	NSString *oldClassName = NSStringFromClass(superCell);
	Class oldClass = [coder classForClassName:oldClassName];
	if(!oldClass)
		oldClass = superCell;
		
	// override what comes out of the unarchiver
	[coder setClass: [[self class] cellClass] forClassName:oldClassName];
		
	// unarchive
	self = [super initWithCoder:coder];
		
	// set it back
	[coder setClass: oldClass forClassName:oldClassName];
	
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{}

+ (Class)cellClass
{
	return [VMCrippledButtonCell class];
}

@end

@implementation VMCrippledButtonCell

- (BOOL)accessibilityIsIgnored
{
	return YES;
}

@end

