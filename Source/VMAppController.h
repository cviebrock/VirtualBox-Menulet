#import <Cocoa/Cocoa.h>
#import "VMPreferences.h"
#import "VMMenuItem.h"

@interface VMAppController : NSObject
{
	NSStatusItem *statusItem;
	NSMenu *statusMenu;
	NSDate *modifiedDate;
	NSMenuItem *startAtLoginItem;
	NSString *settingsPath;
	NSMutableArray *vmMenuItems;
	NSString *runningMachines;
	NSMutableArray *machineLogs;
	BOOL starting;
	VMPreferences *preferences;
	
	NSMutableArray *virtualMachines;
	
	//Shutdown dialog
	IBOutlet id shutWindow;
	IBOutlet id taskText;
	IBOutlet id radioMatrix;
	IBOutlet id progressText;
	IBOutlet id progressIndicator;
	IBOutlet id shutOKButton;
	IBOutlet id shutCancelButton;
	NSString *currentVM;
}

//Main actions
- (void)menuNeedsUpdate:(NSMenu *)menu;
- (void)startMachine:(id)sender;
- (void)launchVB;
- (void)showPreferences;
- (void)quit;
//ShutdownActions
- (IBAction)shutOK:(id)sender;
- (IBAction)shutCancel:(id)sender;
//Global actions
- (void)setup;
- (void)update;
- (void)startVM:(NSString *)uuid;
- (void)stopVM:(NSString *)uuid;
- (NSXMLDocument *)xmlDocumentFromPath:(NSString *)path error:(NSError **)error;
- (VMMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector;
- (int)OSVersion;
- (NSString *)runningMachines;
- (NSString *)runManagerWithOptions:(NSArray *)options;
- (NSDictionary *)runningMachinePIDS;
- (NSArray *)arrayFromString:(NSString *)string;
- (NSImage *)menuImage:(NSImage *)image createHighlighted:(BOOL)highlighted isSMIcon:(BOOL)SMIcon;

@end
