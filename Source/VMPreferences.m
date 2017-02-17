//
//  VMPreferencesController.m
//
//  Created by Maarten Foukhar on 05-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "VMPreferences.h"

@implementation VMPreferences

//////////////////
// Main actions //
//////////////////

#pragma mark -
#pragma mark •• Main actions

- (id)init
{
	if (self = [super init])
	{
		vmOptions = [[NSArray alloc] initWithObjects:	@"VMStartAtLaunch",	//1
														@"VMHeadless",		//2
														@"VMRemoteDesktop",	//3
		nil];
	
		[NSBundle loadNibNamed:@"Preferences" owner:self];
	}

	return self;
}

- (void)awakeFromNib
{
	[prefTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"]];
	[prefWindow setLevel:NSModalPanelWindowLevel];
	
	NSAttributedString *aboutText = [[[NSAttributedString alloc] initWithRTF:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]] documentAttributes:nil] autorelease];
	[[aboutField textStorage] setAttributedString:aboutText];

	[self setup];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];

	[self show];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSInteger selectedTab = [prefTabView indexOfTabViewItem:[prefTabView selectedTabViewItem]];
	[defaults setObject:[NSNumber numberWithInt:selectedTab] forKey:@"VMLastTab"];
}

- (void)dealloc 
{
	[allVirtualMachines release];
	[vmOptions release];
	
	[super dealloc];
}

- (void)show
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[prefWindow makeKeyAndOrderFront:self];
}

- (void)updateWithMachines:(NSArray *)machines
{
	if (allVirtualMachines)
	{
		[allVirtualMachines release];
		allVirtualMachines = nil;
	}
	
	allVirtualMachines = [[NSMutableArray alloc] initWithArray:machines];
	
	[prefTableView reloadData];
}

- (void)setDelegate:(id)del
{
	delegate = del;
}

///////////////////////
// Interface actions //
///////////////////////

#pragma mark -
#pragma mark •• Interface actions

- (IBAction)prefStartAtLogin:(id)sender
{
	NSString *path = [[NSBundle mainBundle] bundlePath];
	[self setStartAtLogin:path enabled:([sender state] == NSOnState)];
}

- (IBAction)showRunningMachines:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:([sender state] == NSOnState) forKey:@"VMShowRunningMachines"];
	[delegate performSelector:@selector(update)];
}

- (IBAction)showStopDialog:(id)sender
{
	BOOL isEnabled = ([sender state] == NSOnState);

	[[NSUserDefaults standardUserDefaults] setBool:isEnabled forKey:@"VMShowStopDialog"];
	
	if (isEnabled)
		[expText setStringValue:NSLocalizedString(@"Click				: show stop dialog\nOption-click		: switch to a machine (when possible)", nil)];
	else
		[expText setStringValue:NSLocalizedString(@"Click				: switch to a machine (when possible)\nOption-click		: show stop dialog", nil)];
}

- (IBAction)prefSettings:(id)sender
{
	if ([prefTableView selectedRow] > - 1)
	{
		int i;
		for (i=0;i<[vmOptions count];i++)
		{
			NSString *currentOption = [vmOptions objectAtIndex:i];
			NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
			NSDictionary *machineOptions = [standardUserDefaults objectForKey:@"Machine Options"];
			
			NSArray *selectedMachines = [self allSelectedItemsInTableView:prefTableView fromArray:allVirtualMachines];
			int lastState = -1;
		
			int x;
			for (x=0;x<[selectedMachines count];x++)
			{
				NSString *selectedMachine = [[selectedMachines objectAtIndex:x] objectForKey:@"UUID"];
				NSDictionary *options = [machineOptions objectForKey:selectedMachine];
					
				int state = [[options objectForKey:currentOption] intValue];
					
				if (lastState == -1 | lastState == state)
				{
					lastState = state;
					[[machineSettings itemAtIndex:i + 1] setState:state];
				}
				else
				{
					[[machineSettings itemAtIndex:i + 1] setState:NSMixedState];
				}
			}
		}

		[machineSettings performClick:self];
	}
}

- (IBAction)prefDisable:(id)sender
{
	if ([prefTableView selectedRow] > - 1)
		[self changeSetting:@"VMHideFromMenu"];
}

- (IBAction)prefMachineDown:(id)sender
{
	NSArray *selectedMachines = [self allSelectedItemsInTableView:prefTableView fromArray:allVirtualMachines];

	int x;
	for (x = [selectedMachines count] - 1;x<[selectedMachines count];x--)
	{
		NSDictionary *machine = [selectedMachines objectAtIndex:x];
		int index = [allVirtualMachines indexOfObject:machine];
		int destIndex = index + 1;
		
		if (destIndex == [allVirtualMachines count])
			break;
		
		[self moveRowAtIndex:index toIndex:destIndex];
	}
}

- (IBAction)prefMachineUp:(id)sender
{
	NSArray *selectedMachines = [self allSelectedItemsInTableView:prefTableView fromArray:allVirtualMachines];

	int x;
	for (x = 0;x<[selectedMachines count];x++)
	{
		NSDictionary *machine = [selectedMachines objectAtIndex:x];
		int index = [allVirtualMachines indexOfObject:machine];
		int destIndex = index - 1;
		
		if (destIndex == -1)
			break;
		
		[self moveRowAtIndex:index toIndex:destIndex];
	}
}

- (void)setVMOptions:(id)sender
{
	NSInteger index = [[sender menu] indexOfItem:sender] - 1;
	NSString *key = [vmOptions objectAtIndex:index];
	[self changeSetting:key];
}

///////////////////
// Other actions //
///////////////////

#pragma mark -
#pragma mark •• Other actions

- (void)setup
{	
	NSRect frame = [prefSettings frame];
	machineSettings = [[NSPopUpButton alloc] initWithFrame:frame pullsDown:YES];
	[[prefSettings superview] addSubview:machineSettings];
	[machineSettings setFrame:NSMakeRect(frame.origin.x - 3, frame.origin.y - 3, frame.size.width, frame.size.height)];
	[machineSettings setHidden:YES];
	[machineSettings addItemWithTitle:@""];
	
	NSMenu *menu = [machineSettings menu];
	[menu addItem:[self menuItemWithTitle:NSLocalizedString(@"Start at Launch", nil) action:@selector(setVMOptions:)]];
	[menu addItem:[self menuItemWithTitle:NSLocalizedString(@"Run in Headless Mode", nil) action:@selector(setVMOptions:)]];
	[menu addItem:[self menuItemWithTitle:NSLocalizedString(@"Run in Remote Desktop Server Mode", nil) action:@selector(setVMOptions:)]];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *selectedTab = [defaults objectForKey:@"VMLastTab"];
	
	if (selectedTab)
		[prefTabView selectTabViewItemAtIndex:[selectedTab intValue]];
		
	NSNumber *boolNumber = [defaults objectForKey:@"VMShowRunningMachines"];
	
	if (boolNumber)
		[showRunningMachines setState:[boolNumber intValue]];
		
	boolNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"VMShowStopDialog"];
	
	if (boolNumber)
		[showStopDialog setState:[boolNumber intValue]];
		
	[self showStopDialog:showStopDialog];
}

- (void)update
{
	NSNumber *boolNumber = [NSNumber numberWithBool:[self shouldStartVBMenuletAtLogin]];
	[prefStartAtLogin setState:[boolNumber intValue]];
}

- (BOOL)shouldStartVBMenuletAtLogin
{
	BOOL result;

	if ([self OSVersion] >= 0x1050)
	{
		NSTask *loginhelper = [[NSTask alloc] init];
		[loginhelper setLaunchPath:[[NSBundle mainBundle] pathForResource:@"loginhelper" ofType:@""]];
		[loginhelper setArguments:[NSArray arrayWithObjects:@"checklogin", [[NSBundle mainBundle] bundlePath], nil]];
		[loginhelper launch];
		[loginhelper waitUntilExit];
		result = ([loginhelper terminationStatus] == 1);
		[loginhelper release];
	}
	else
	{
		result = [[NSUserDefaults standardUserDefaults] boolForKey:@"VMStartAtLogin"];
	}
	
	return result;
}

//And this too, used to use AppleScript
- (void)setStartAtLogin:(NSString *)path enabled:(BOOL)enabled
{
	if ([self OSVersion] >= 0x1050)
	{
		NSString *argument;
		
		if (enabled)
			argument = @"setlogin";
		else
			argument = @"unsetlogin";
	
		NSTask *loginhelper = [[NSTask alloc] init];
		[loginhelper setLaunchPath:[[NSBundle mainBundle] pathForResource:@"loginhelper" ofType:@""]];
		[loginhelper setArguments:[NSArray arrayWithObjects:argument, path, nil]];
		[loginhelper launch];
		[loginhelper waitUntilExit];
		[loginhelper release];
	}
	else
	{
		NSString *script;
		if (enabled)
			script = [NSString stringWithFormat:@"tell application \"System Events\" \n make login item at end with properties {path:\"%@\", hidden:false} \n end tell", path];
		else
			script = [NSString stringWithFormat:@"tell application \"System Events\" \n delete login item \"%@\" \n end tell", [[NSFileManager defaultManager] displayNameAtPath:path]];
	
		NSAppleScript *scriptObject = [[NSAppleScript alloc] initWithSource:script];
		[scriptObject executeAndReturnError:nil];
		[scriptObject release];
	
		[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"VMStartAtLogin"];
	}
}

- (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector
{
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
	[menuItem setTarget:self];
	
	return [menuItem autorelease];
}

- (int)OSVersion
{
	SInt32 MacVersion;
	
	Gestalt(gestaltSystemVersion, &MacVersion);
	
	return (int)MacVersion;
}

- (void)changeSetting:(NSString *)key
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	NSArray *selectedMachines = [self allSelectedItemsInTableView:prefTableView fromArray:allVirtualMachines];
	BOOL state = NO;
		
	if ([selectedMachines count] > 1)
	{
		int x;
		for (x=0;x<[selectedMachines count];x++)
		{
			NSDictionary *machineOptions = [standardUserDefaults objectForKey:@"Machine Options"];
			NSString *selectedMachine = [[selectedMachines objectAtIndex:x] objectForKey:@"UUID"];
			NSDictionary *options = [machineOptions objectForKey:selectedMachine];
			int stateInte = [[options objectForKey:key] intValue];

			if (stateInte == 0)
				state = YES;
		}
	}
		
	int x;
	for (x=0;x<[selectedMachines count];x++)
	{
		NSMutableDictionary *machineOptions = [NSMutableDictionary dictionaryWithDictionary:[standardUserDefaults objectForKey:@"Machine Options"]];
		NSString *selectedMachine = [[selectedMachines objectAtIndex:x] objectForKey:@"UUID"];
		NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[machineOptions objectForKey:selectedMachine]];
			
		if ([selectedMachines count] > 1)
		{
			[options setObject:[NSNumber numberWithBool:state] forKey:key];
		}
		else
		{
			BOOL oldState = [[options objectForKey:key] boolValue];
			[options setObject:[NSNumber numberWithBool:!oldState] forKey:key];
		}
			
		[machineOptions setObject:options forKey:selectedMachine];
		[standardUserDefaults setObject:machineOptions forKey:@"Machine Options"];

		[prefTableView reloadData];
		[delegate performSelector:@selector(update)];
	}
}

- (void)moveRowAtIndex:(int)index toIndex:(int)destIndex
{
	NSArray *allSelectedItems = [self allSelectedItemsInTableView:prefTableView fromArray:allVirtualMachines];
	NSData *data = [NSArchiver archivedDataWithRootObject:[allVirtualMachines objectAtIndex:index]];
	BOOL isSelected = [allSelectedItems containsObject:[allVirtualMachines objectAtIndex:index]];
		
	if (isSelected)
		[prefTableView deselectRow:index];
	
	if (destIndex < index)
	{
		int x;
		for (x = index;x>destIndex;x--)
		{
			id object = [allVirtualMachines objectAtIndex:x - 1];
	
			[allVirtualMachines replaceObjectAtIndex:x withObject:object];
		
			if ([allSelectedItems containsObject:object])
			{
				[prefTableView deselectRow:x - 1];
				[prefTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
			}
		}
	}
	else
	{
		int x;
		for (x = index;x<destIndex;x++)
		{
			id object = [allVirtualMachines objectAtIndex:x + 1];
	
			[allVirtualMachines replaceObjectAtIndex:x withObject:object];
		
			if ([allSelectedItems containsObject:object])
			{
				[prefTableView deselectRow:x + 1];
				[prefTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
			
			}
		}
	}
	
	[allVirtualMachines replaceObjectAtIndex:destIndex withObject:[NSUnarchiver unarchiveObjectWithData:data]];
				
	[prefTableView reloadData];
	
	if (isSelected)
		[prefTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:destIndex] byExtendingSelection:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:allVirtualMachines forKey:@"Machines"];
	[delegate performSelector:@selector(update)];
}

//////////////////////
// Tableview actions //
///////////////////////

#pragma mark -
#pragma mark •• Tableview actions

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [allVirtualMachines count];
}

//return selected row
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *rowData = [allVirtualMachines objectAtIndex:row];
	return [rowData objectForKey:[tableColumn identifier]];
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{    return NO; }

//Needed to be able to drag rows
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	int result = NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
	NSArray *rows = [NSUnarchiver unarchiveObjectWithData:data];
	int firstIndex = [[rows objectAtIndex:0] intValue];
	
	if (row > firstIndex - 1 && row < firstIndex + [rows count] + 1)
		return result;

    if (op == NSTableViewDropAbove) {
        result = NSDragOperationMove;
    }

    return (result);
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard *pboard = [info draggingPasteboard];

	if ([[pboard types] containsObject:@"NSGeneralPboardType"])
	{
		NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
		NSArray *rows = [NSUnarchiver unarchiveObjectWithData:data];
		int firstIndex = [[rows objectAtIndex:0] intValue];
	
		NSMutableArray *machines = [NSMutableArray array];
		
		int x;
		for (x = 0;x < [rows count];x++)
		{
			[machines addObject:[allVirtualMachines objectAtIndex:[[rows objectAtIndex:x] intValue]]];
		}
		
		if (firstIndex < row)
		{
			for (x = 0;x < [machines count];x++)
			{
				int index = row - 1;
				
				[self moveRowAtIndex:[allVirtualMachines indexOfObject:[machines objectAtIndex:x]] toIndex:index];
			}
		}
		else
		{
			for (x = [machines count] - 1;x < [machines count];x--)
			{
				int index = row;
				
				[self moveRowAtIndex:[allVirtualMachines indexOfObject:[machines objectAtIndex:x]] toIndex:index];
			}
		}
	}
	
    return YES;
}

- (BOOL)tableView:(NSTableView *)view writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
	NSData *data = [NSArchiver archivedDataWithRootObject:rows];
	[pboard declareTypes: [NSArray arrayWithObjects:@"NSGeneralPboardType", nil] owner:nil];
	[pboard setData:data forType:@"NSGeneralPboardType"];
   
	return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *machineOptions = [standardUserDefaults objectForKey:@"Machine Options"];
	NSDictionary *options = [machineOptions objectForKey:[[allVirtualMachines objectAtIndex:rowIndex] objectForKey:@"UUID"]];
					
	if ([[options objectForKey:@"VMHideFromMenu"] boolValue])
		[aCell setTextColor:[NSColor lightGrayColor]];
	else
		[aCell setTextColor:[NSColor blackColor]];
}

- (NSArray*)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array
{
	NSMutableArray *items = [NSMutableArray array];
	NSIndexSet *indexSet = [tableView selectedRowIndexes];
	
	NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound)
    {
		if ([array objectAtIndex:current_index]) 
			[items addObject:[array objectAtIndex:current_index]];
			
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }

	return items;
}

@end
