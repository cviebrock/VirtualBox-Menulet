#import "VMAppController.h"

@implementation VMAppController

- (id)init
{
	self = [super init];
	
	runningMachines = [[self runningMachines] retain];
	
	starting = YES;
	
	//Store the modification date so we can update the menu if needed
	settingsPath = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"VirtualBox"] stringByAppendingPathComponent:@"VirtualBox.xml"] retain];
	NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:settingsPath traverseLink:YES];
	modifiedDate = [[attributes objectForKey:NSFileModificationDate] retain];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	
    NSImage *normalSMIcon = [NSImage imageNamed:@"SMIcon"];
	
	if (normalSMIcon)
	{
        [statusItem setImage:normalSMIcon];
//		[statusItem setAlternateImage:highlightedSMIcon];
	}
	else
	{
		[statusItem setTitle:@"VB"];
	}
	
	[statusItem setHighlightMode:YES];
	
	vmMenuItems = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc 
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (virtualMachines)
		[virtualMachines release];
		
	[statusItem release];
	[settingsPath release];
	[vmMenuItems release];
	[runningMachines release];
	
	[super dealloc];
}

- (void)awakeFromNib
{	
	//Populate our menu
	[self setup];
}

///////////////////
// Main actions //
///////////////////

#pragma mark -
#pragma mark •• Main actions

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:settingsPath traverseLink:YES];
	NSDate *newModifiedDate = [attributes objectForKey:NSFileModificationDate];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL needsUpdate = NO;
	
	BOOL showRunning = YES;
	NSNumber *boolNumber = [defaults objectForKey:@"VMShowRunningMachines"];
	
	if (boolNumber)
		showRunning = [boolNumber boolValue];
	
	if (showRunning)
	{
		NSString *updatedRunningMachines = [self runningMachines];
		if (![runningMachines isEqualTo:updatedRunningMachines])
		{
			[runningMachines release];
			runningMachines = [updatedRunningMachines retain];
		
			needsUpdate = YES;
		}
	}
	
	//Update when modified
	if (![modifiedDate isEqualTo:newModifiedDate])
	{
		[modifiedDate release];
		
		modifiedDate = [newModifiedDate retain]; 
		needsUpdate = YES;
	}
	
	if (needsUpdate)
		[self update];

	NSArray *items = [statusMenu itemArray];
	
	int i;
	for (i=0;i<[items count];i++)
	{
		id curItem = [items objectAtIndex:i];
		
		if ([curItem isKindOfClass:[VMMenuItem class]])
			[(VMMenuItem *)curItem setHighlighted:NO];
	}
}

- (void)startMachine:(id)sender
{
	NSString *vmName = [[virtualMachines objectAtIndex:[statusMenu indexOfItem:sender]] objectForKey:@"Name"];
	NSString *uuid = [[virtualMachines objectAtIndex:[statusMenu indexOfItem:sender]] objectForKey:@"UUID"];

	NSString *updatedRunningMachines = [self runningMachines];
	if (![runningMachines isEqualTo:updatedRunningMachines])
	{
		[runningMachines release];
		runningMachines = [updatedRunningMachines retain];
	}

	if ([runningMachines rangeOfString:[NSString stringWithFormat:@"\"%@\"", vmName]].length > 0)
		[self stopVM:uuid];
	else
		[self startVM:uuid];
}

- (void)launchVB
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"VirtualBox"];
}

- (void)showPreferences
{
	if (!preferences)
	{
		preferences = [[VMPreferences alloc] init];
		[preferences setDelegate:self];
		[self update];
	}
	else
	{
		[preferences show];
	}
}

- (void)quit
{
	[NSApp terminate:self];
}

//////////////////////
// Shutdown actions //
//////////////////////

#pragma mark -
#pragma mark •• Shutdown actions

- (IBAction)shutOK:(id)sender
{
	int selectedRow = [radioMatrix selectedRow];
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *machineOptions = [NSMutableDictionary dictionaryWithDictionary:[standardDefaults objectForKey:@"Machine Options"]];
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[machineOptions objectForKey:currentVM]];

	[options setObject:[NSNumber numberWithInt:selectedRow] forKey:@"VMShutdownOption"];
	[machineOptions setObject:options forKey:currentVM];
	
	[standardDefaults setObject:machineOptions forKey:@"Machine Options"];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"controlvm", currentVM, nil];
	
	NSString *taskString;
	
		if (selectedRow == 0)
		{
			taskString = NSLocalizedString(@"Saving state…", nil);
			[arguments addObject:@"savestate"];
		}
		else if (selectedRow == 1)
		{
			taskString = NSLocalizedString(@"Sending shutdown signal…", nil);
			[arguments addObject:@"acpipowerbutton"];
		}
		else if (selectedRow == 2)
		{
			taskString = NSLocalizedString(@"Powering machine off…", nil);
			[arguments addObject:@"poweroff"];
		}
			
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	[progressText setHidden:NO];
	[progressText setStringValue:taskString];
	[shutOKButton setEnabled:NO];
	[shutCancelButton setEnabled:NO];
	[radioMatrix setEnabled:NO];
	
	[NSThread detachNewThreadSelector:@selector(shutdown:) toTarget:self withObject:arguments];
}

- (void)shutdown:(NSArray *)arguments
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self runManagerWithOptions:arguments];
	
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
	[progressText setHidden:YES];
	
	[shutOKButton setEnabled:YES];
	[shutCancelButton setEnabled:YES];
	[radioMatrix setEnabled:YES];
	
	[self shutCancel:self];
	[NSApp hide:self];
	
	[pool release];
}

- (IBAction)shutCancel:(id)sender
{
	[NSApp stopModal];
	[shutWindow orderOut:self];
}

////////////////////
// Global actions //
////////////////////

#pragma mark -
#pragma mark •• Global actions

- (void)setup
{
	statusMenu = [[[NSMenu alloc] initWithTitle:@"Status Menu"] autorelease];
	[statusMenu setDelegate:self];
	
	[statusMenu addItem:[NSMenuItem separatorItem]];
	[statusMenu addItem:[self menuItemWithTitle:NSLocalizedString(@"Launch VirtualBox", nil) action:@selector(launchVB)]];
	[statusMenu addItem:[NSMenuItem separatorItem]];
	[statusMenu addItem:[self menuItemWithTitle:NSLocalizedString(@"Preferences…", nil) action:@selector(showPreferences)]];
	[statusMenu addItem:[self menuItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit)]];
	[statusItem setMenu:statusMenu];
	
	[self update];
	
	/*NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	if ([[standardDefaults objectForKey:@"VMPreferencesVersion"] intValue] < 1)
	{
		[standardDefaults synchronize];
		[self update];
		[standardDefaults setObject:[NSNumber numberWithDouble:1.0] forKey:@"VMPreferencesVersion"];
	}*/
		
}

- (void)update
{
	BOOL showRunning = YES;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *boolNumber = [defaults objectForKey:@"VMShowRunningMachines"];
	NSMutableArray *allVirtualMachines;
	
	if (boolNumber)
		showRunning = [boolNumber boolValue];

	int i;
	for (i=0;i<[vmMenuItems count];i++)
	{
		[statusMenu removeItem:[vmMenuItems objectAtIndex:i]];
	}
	
	[vmMenuItems removeAllObjects];

	NSError *error = nil;
	NSXMLDocument *settingsXML = [self xmlDocumentFromPath:settingsPath error:&error];
	
	if (!error)
	{
		NSArray *nodes = [settingsXML nodesForXPath:@"./VirtualBox/Global/MachineRegistry/MachineEntry" error:&error];
		
		if (!error)
		{
			if (virtualMachines)
				[virtualMachines release];
		
			virtualMachines = [[NSMutableArray alloc] init];
			allVirtualMachines = [NSMutableArray array];
			
			NSMutableArray *machines = [defaults objectForKey:@"Machines"];
			NSMutableArray *existingMachines = [NSMutableArray array];
			NSMutableArray *newMachines = [NSMutableArray array];
			
			int i;
			for (i=0;i<[nodes count];i++)
			{
				NSXMLElement *node = [nodes objectAtIndex:i];
				NSString *machinePath = [[node attributeForName:@"src"] stringValue];
				
				if (![[machinePath substringWithRange:NSMakeRange(0, 1)] isEqualTo:@"/"])
					machinePath = [NSString stringWithFormat:@"%@/%@", [settingsPath stringByDeletingLastPathComponent], machinePath];

				settingsXML = [self xmlDocumentFromPath:machinePath	error:&error];
				
				NSArray *machineNodes;
				
				if (!error)
					machineNodes = [settingsXML nodesForXPath:@"./VirtualBox/Machine" error:&error];
				else
					break;
				
				if (!error)
				{
					NSString *vmName = [[[machineNodes objectAtIndex:0] attributeForName:@"name"] stringValue];
					NSString *uuid = [[[machineNodes objectAtIndex:0] attributeForName:@"uuid"] stringValue];
					uuid = [uuid substringWithRange:NSMakeRange(1, [uuid length] - 2)];
					NSDictionary *vmDict = [NSDictionary dictionaryWithObjectsAndKeys:vmName, @"Name", uuid, @"UUID", nil];
					NSDictionary *oldVMDict = [NSDictionary dictionaryWithObjectsAndKeys:vmName, @"Name", nil];
					
					if ([machines containsObject:vmDict])
					{
						[existingMachines addObject:vmDict];
					}
					else if ([machines containsObject:oldVMDict])
					{
						[machines replaceObjectAtIndex:[machines indexOfObject:oldVMDict] withObject:vmDict];
						[existingMachines addObject:vmDict];
					}
					else
					{
						[newMachines addObject:vmDict];
					}
				}
			}
			
			int menuItemIndex = 0;
			
			for (i=0;i<[machines count];i++)
			{
				NSDictionary *machine = [machines objectAtIndex:i];

				if ([existingMachines containsObject:machine])
				{
					NSString *machineName = [machine objectForKey:@"Name"];
					NSString *uuid = [machine objectForKey:@"UUID"];
					NSDictionary *machineOptions = [defaults objectForKey:@"Machine Options"];
					
					//Convert the machine options to new style options
					if (![[machineOptions allKeys] containsObject:uuid])
					{
						if ([[machineOptions allKeys] containsObject:machineName])
						{
							NSMutableDictionary *newMachineOptions = [machineOptions mutableCopy];
							NSMutableDictionary *options = [[newMachineOptions objectForKey:machineName] mutableCopy];
							[options setObject:machineName forKey:@"VMMachineName"];
							[newMachineOptions removeObjectForKey:machineName];
							[newMachineOptions setObject:options forKey:uuid];
							[defaults setObject:newMachineOptions forKey:@"Machine Options"];
							machineOptions = [defaults objectForKey:@"Machine Options"];
							[newMachineOptions release];
							[options release];
						}
					}
					
					NSDictionary *options = [machineOptions objectForKey:uuid];
					
					if (starting && [[options objectForKey:@"VMStartAtLaunch"] boolValue])
						[self startVM:uuid];
					
					if (![[options objectForKey:@"VMHideFromMenu"] boolValue])
					{
						NSString *menuName = machineName;
					
						VMMenuItem *vmItem = [self menuItemWithTitle:menuName action:@selector(startMachine:)];
						
						NSString *imageName;
						if ([runningMachines rangeOfString:[NSString stringWithFormat:@"\"%@\"", machineName]].length > 0)
							imageName = @"VMRunning";
						else
							imageName = @"VMShut";
						
                        NSImage *image = [NSImage imageNamed:imageName];
						[image setTemplate:YES];
                        
						[vmItem setIcon:[self menuImage:image isSMIcon:NO]];
//						[vmItem setAlternateIcon:[self menuImage:image createHighlighted:YES isSMIcon:NO]];
						
						[vmMenuItems addObject:vmItem];
						[statusMenu insertItem:vmItem atIndex:menuItemIndex];
						menuItemIndex = menuItemIndex + 1;
						
						[virtualMachines addObject:machine];
					}
					
					[allVirtualMachines addObject:machine];
				}
			}
			
			for (i=0;i<[newMachines count];i++)
			{
				NSDictionary *machine = [newMachines objectAtIndex:i];
				
				NSString *machineName = [machine objectForKey:@"Name"];
				NSString *uuid = [machine objectForKey:@"UUID"];
				NSDictionary *machineOptions = [defaults objectForKey:@"Machine Options"];
					
				if (!machineOptions)
					machineOptions = [[NSMutableDictionary alloc] init];
					
				NSMutableDictionary *newMachineOptions = [machineOptions mutableCopy];
				NSMutableDictionary *options = [NSMutableDictionary dictionary];
				[options setObject:machineName forKey:@"VMMachineName"];
				[newMachineOptions setObject:options forKey:uuid];
				[defaults setObject:newMachineOptions forKey:@"Machine Options"];
				[newMachineOptions release];
					
				VMMenuItem *vmItem = [self menuItemWithTitle:machineName action:@selector(startMachine:)];
				
				NSString *imageName;
				if ([runningMachines rangeOfString:[NSString stringWithFormat:@"\"%@\"", machineName]].length > 0)
					imageName = @"VMRunning";
				else
					imageName = @"VMShut";
						
				NSImage *image = [NSImage imageNamed:imageName];
				
				[vmItem setIcon:[self menuImage:image isSMIcon:NO]];
//				[vmItem setAlternateIcon:[self menuImage:image createHighlighted:YES isSMIcon:NO]];
				
				[vmMenuItems addObject:vmItem];
				[statusMenu insertItem:vmItem atIndex:menuItemIndex];
				menuItemIndex = menuItemIndex + 1;
					
				[virtualMachines addObject:machine];
				[allVirtualMachines addObject:machine];
			}
		}
		
		[defaults setObject:allVirtualMachines forKey:@"Machines"];
		
		if (preferences)
			[preferences updateWithMachines:allVirtualMachines];
		
		starting = NO;
	}
	
	if (error)
	{
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to open VirtualBox settings file", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:[error localizedDescription]];
		[alert runModal];
		[NSApp terminate:self];
	}
}

- (void)startVM:(NSString *)uuid
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"startvm"];
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *machineOptions = [standardDefaults objectForKey:@"Machine Options"];
		
	if (machineOptions)
	{
		NSDictionary *options = [machineOptions objectForKey:uuid];
					
		if ([[options objectForKey:@"VMRemoteDesktop"] boolValue])
		{
			[arguments addObject:@"--type"];
			[arguments addObject:@"vrdp"];
		}
		else if ([[options objectForKey:@"VMHeadless"] boolValue])
		{
			[arguments addObject:@"--type"];
			[arguments addObject:@"headless"];
		}
	}
		
	[arguments addObject:uuid];
	
	[self runManagerWithOptions:arguments];
}

- (void)stopVM:(NSString *)uuid
{
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *boolNumber = [standardDefaults objectForKey:@"VMShowStopDialog"];
	BOOL showDialog = NO;
	BOOL background = NO;
	
	if (boolNumber)
		showDialog = [boolNumber boolValue];
		
	NSDictionary *machineOptions = [standardDefaults objectForKey:@"Machine Options"];
	NSDictionary *options = [machineOptions objectForKey:uuid];
					
	if ([[options objectForKey:@"VMRemoteDesktop"] boolValue])
		background = YES;
	else if ([[options objectForKey:@"VMHeadless"] boolValue])
		background = YES;

	NSEvent *event = [NSApp currentEvent];
	BOOL isOptionKey = NO;
	
	if (event != nil)
		isOptionKey = ([event modifierFlags] & NSAlternateKeyMask) != 0 ;
	
	if ((isOptionKey && !showDialog) | (!isOptionKey && showDialog) | background)
	{
		currentVM = uuid;
		[taskText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"'%@' is currently running", nil), [options objectForKey:@"VMMachineName"]]];
	
		NSNumber *selectedOption;
		
		NSDictionary *machineOptions = [standardDefaults objectForKey:@"Machine Options"];
		
		if (machineOptions)
		{
			NSDictionary *options = [machineOptions objectForKey:uuid];
			selectedOption = [options objectForKey:@"VMShutdownOption"];
		}
	
		if (!selectedOption)
			selectedOption = [NSNumber numberWithInt:0];
		
		[radioMatrix selectCellAtRow:[selectedOption intValue] column:0];
	
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		[NSApp runModalForWindow:shutWindow];
	}
	else
	{
		int	aProcessIdentifier = [[[self runningMachinePIDS] objectForKey:uuid] intValue];
		ProcessSerialNumber	aProcessSerialNumber;
		OSStatus aStatus = GetProcessForPID(aProcessIdentifier, &aProcessSerialNumber);
	
		if ( aStatus == noErr )
			SetFrontProcess(&aProcessSerialNumber);
	}

	
}

- (NSXMLDocument *)xmlDocumentFromPath:(NSString *)path error:(NSError **)error
{
	NSError *myError = nil;
	NSFileManager *defaultManager = [NSFileManager defaultManager];

	if (![defaultManager fileExistsAtPath:path])
	{
		NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
		[infoDict setObject:[NSString stringWithFormat:NSLocalizedString(@"Unable to find '%@' in the folder '%@'", nil), [defaultManager displayNameAtPath:path], [defaultManager displayNameAtPath:[path stringByDeletingLastPathComponent]]] forKey:NSLocalizedDescriptionKey];
		
		*error = [NSError errorWithDomain:@"VMErrorDomain" code:1 userInfo:infoDict];
		return nil;
	}
	
	NSURL *xmlURL = [NSURL fileURLWithPath:path];
	NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:xmlURL options:0 error:&myError];
	
	if (myError)
	{
		*error = myError;
		return nil;
	}

	return [xmlDocument autorelease];
}

- (VMMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector
{
	VMMenuItem *menuItem = [[VMMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
	[menuItem setTarget:self];
	
	return [menuItem autorelease];
}

- (int)OSVersion
{
	SInt32 MacVersion;
	
	Gestalt(gestaltSystemVersion, &MacVersion);
	
	return (int)MacVersion;
}

- (NSString *)runningMachines
{
	NSString *machines = [self runManagerWithOptions:[NSArray arrayWithObjects:@"list", @"runningvms", nil]];
	
	return machines;
}

- (NSString *)runManagerWithOptions:(NSArray *)options
{
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	
	//Launch virtual machine after checking if the command line tools are installed
	NSString *vbmanagePath = @"/usr/bin/VBoxManage";
	
	if (![defaultManager fileExistsAtPath:vbmanagePath])
	{
		NSString *vmAppLocation = [standardDefaults objectForKey:@"VMAppLocation"];
	
		if (!vmAppLocation)
			vmAppLocation = @"/Applications/VirtualBox.app";
	
		vbmanagePath = [[[vmAppLocation stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"VBoxManage"];
	
		if (![defaultManager fileExistsAtPath:vbmanagePath])
		{
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to find the VirtualBox application", nil) defaultButton:NSLocalizedString(@"Locate", nil) alternateButton:NSLocalizedString(@"Cancel", nil) otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please locate the VirtualBox application", nil)];
			int result = [alert runModal];
		
			if (result == NSAlertDefaultReturn)
			{
				NSOpenPanel *openPanel = [NSOpenPanel openPanel];
				result = [openPanel runModalForTypes:[NSArray arrayWithObject:@"app"]];
			
				if (result == NSOKButton)
				{
					NSString *appPath = [openPanel filename];
					[standardDefaults setObject:appPath forKey:@"VMAppLocation"];
					vbmanagePath = [[[appPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"VBoxManage"];
				}
			}
		}
	}
	
	if ([defaultManager fileExistsAtPath:vbmanagePath])
	{
		NSTask *vboxManage = [[NSTask alloc] init];
		[vboxManage setLaunchPath:vbmanagePath];
		[vboxManage setArguments:options];
		
		NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
		[environment setObject:@"en_US.UTF-8" forKey:@"LC_ALL"];
		[vboxManage setEnvironment:environment];
		
		NSPipe *outputPipe = [[NSPipe alloc] init];
		[vboxManage setStandardOutput:outputPipe];
		NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
		
		[vboxManage launch];
		
		NSData *outputData = [fileHandle readDataToEndOfFile];
		NSString *dataString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

		[vboxManage waitUntilExit];
	
		if ([dataString rangeOfString:@"ERROR:"].length > 0 && [options containsObject:@"startvm"])
		{
			[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Failed to launch virtual machine", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Try opening it in the main VirtualBox application", nil)];
			[alert runModal];
		}
		
		if ([dataString rangeOfString:@"Already paused"].length > 0)
		{
			[self runManagerWithOptions:[NSArray arrayWithObjects:@"controlvm", [options objectAtIndex:1], @"resume", nil]];
			[self runManagerWithOptions:options];
		}
	
		[vboxManage release];
		[outputPipe release];
		
		return [dataString autorelease];
	}
	else
	{
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Missing command line tools", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"VirtualBox command line utilities must be installed", nil)];
		[alert runModal];
	}
	
	return @"";
}

- (NSDictionary *)runningMachinePIDS
{
	NSTask *ps = [[NSTask alloc] init];
	[ps setLaunchPath:@"/bin/ps"];
	[ps setArguments:[NSArray arrayWithObjects:@"-A", @"-w", @"-w", nil]];
	
	NSPipe *outputPipe = [[NSPipe alloc] init];
	[ps setStandardOutput:outputPipe];
	NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
	[ps launch];
	
	NSData *outputData = [fileHandle readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
	[ps waitUntilExit];
	
	[ps release];
	[outputPipe release];
	
	NSArray *sentences = [outputString componentsSeparatedByString:@"\n"];
	NSMutableDictionary *pidDict = [NSMutableDictionary dictionary];
	
	int i;
	for (i=0;i<[sentences count];i++)
	{
		NSString *sentence = [sentences objectAtIndex:i];

		if ([sentence rangeOfString:@"VirtualBoxVM"].length > 0)
		{
			NSArray *strings = [self arrayFromString:sentence];
			NSNumber *pid = [strings objectAtIndex:0];
				
			NSString *machine = [[[[sentence componentsSeparatedByString:@"--startvm "] objectAtIndex:1] componentsSeparatedByString:@" --"] objectAtIndex:0];

			[pidDict setObject:pid forKey:machine];
		}
	}
	
	return pidDict;
}

- (NSArray *)arrayFromString:(NSString *)string
{
	NSArray *parts = [string componentsSeparatedByString:@" "];
	NSMutableArray *newArray = [NSMutableArray array];
	
	int i;
	for (i=0;i<[parts count];i++)
	{
		NSString *part = [parts objectAtIndex:i];
		
		if (![part isEqualTo:@""])
			[newArray addObject:part];
	}
	
	return newArray;
}

- (NSImage *)menuImage:(NSImage *)image isSMIcon:(BOOL)SMIcon
{
	NSSize imageSize = [image size];
    
    
	if (!SMIcon)
		imageSize = NSMakeSize(10, 10);
	
	int width = imageSize.width;
	int height = imageSize.height;
	
	NSImage *newImage = [[NSImage alloc] initWithSize:imageSize];
	
    [newImage lockFocus];
    [newImage setTemplate:YES];
	
    
	[image drawInRect:NSMakeRect(0, 0, width, height) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
		
	[newImage unlockFocus];
		
	return [newImage autorelease];
}

//Only works from 10.5 :-(
- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
	NSArray *items = [statusMenu itemArray];
	
	int i;
	for (i=0;i<[items count];i++)
	{
		id curItem = [items objectAtIndex:i];
		
		if ([curItem isKindOfClass:[VMMenuItem class]])
		{
			if ([curItem isEqualTo:item])
				[(VMMenuItem *)curItem setHighlighted:YES];
			else
				[(VMMenuItem *)curItem setHighlighted:NO];
		}
	}
}

@end
