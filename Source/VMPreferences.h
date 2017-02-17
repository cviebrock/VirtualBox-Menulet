//
//  VMPreferencesController.h
//
//  Created by Maarten Foukhar on 05-07-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VMPreferences : NSObject
{
	//Interface objects
	IBOutlet id prefWindow;
	IBOutlet id prefStartAtLogin;
	IBOutlet id showRunningMachines;
	IBOutlet id showStopDialog;
	IBOutlet id expText;
	IBOutlet id prefTableView;
	IBOutlet id prefSettings;
	IBOutlet id prefTabView;
	IBOutlet id aboutField;
	
	//Other objects
	NSPopUpButton *machineSettings;
	NSMutableArray *allVirtualMachines;
	NSArray *vmOptions;
	id delegate;
}

//main actions
- (void)show;
- (void)updateWithMachines:(NSArray *)machines;
- (void)setDelegate:(id)del;

//Interface actions
- (IBAction)prefStartAtLogin:(id)sender;
- (IBAction)showRunningMachines:(id)sender;
- (IBAction)showStopDialog:(id)sender;
- (IBAction)prefSettings:(id)sender;
- (IBAction)prefDisable:(id)sender;
- (IBAction)prefMachineDown:(id)sender;
- (IBAction)prefMachineUp:(id)sender;
- (void)setVMOptions:(id)sender;

//Other actions
- (void)setup;
- (void)update;
- (BOOL)shouldStartVBMenuletAtLogin;
- (void)setStartAtLogin:(NSString *)path enabled:(BOOL)enabled;
- (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector;
- (int)OSVersion;
- (void)changeSetting:(NSString *)key;
//- (void)moveRows:(int)move withMachines:(NSArray *)machines;
- (void)moveRowAtIndex:(int)index toIndex:(int)destIndex;

//Tableview actions
- (NSArray*)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array;

@end
