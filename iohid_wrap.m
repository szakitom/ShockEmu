#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOTypes.h>
#include <IOKit/IOReturn.h>
#include <IOKit/hid/IOHIDLib.h>
//#include <IOKit/hid/IOHIDManager.h>
#import <objc/runtime.h>

#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>

#include <string.h> 
#include <fcntl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 

/*
 * macOS 11+ / dyld4: DYLD_FORCE_FLAT_NAMESPACE no longer redirects imports that
 * resolve into the dyld shared cache, so simply exporting same-named symbols is
 * silently ignored. Explicit interposing via __DATA,__interpose still works.
 */
#define DYLD_INTERPOSE(_repl, _orig) \
	__attribute__((used)) static struct { const void *repl; const void *orig; } \
	_interpose_##_orig __attribute__((section("__DATA,__interpose"))) = \
	{ (const void *) &_repl, (const void *) &_orig };



typedef struct {
	uint8_t id, 
	left_x, left_y, 
	right_x, right_y, 
	buttons1, buttons2, buttons3, 
	left_trigger, right_trigger, 
	unk1, unk2, unk3;
	int16_t gyro_x, gyro_y, gyro_z;
	int16_t accel_x, accel_y, accel_z;
	uint8_t unk4[39];
} PSReport;

IOHIDManagerRef se_IOHIDManagerCreate( CFAllocatorRef allocator, IOOptionBits options) {
	printf("IOHIDManagerCreate\n");
	return (IOHIDManagerRef) 0xDEADBEEF;
}

IOReturn se_IOHIDManagerOpen( IOHIDManagerRef manager, IOOptionBits options) {
	printf("IOHIDManagerOpen\n");
	return kIOReturnSuccess;
}

IOReturn se_IOHIDManagerClose( IOHIDManagerRef manager, IOOptionBits options) {
	printf("IOHIDManagerClose\n");
	return kIOReturnSuccess;
}

CFSetRef se_IOHIDManagerCopyDevices( IOHIDManagerRef manager) {
	IOHIDDeviceRef dev = (IOHIDDeviceRef) 0xDEADBEEF;
	IOHIDDeviceRef devs[1] = {dev};
	printf("IOHIDManagerCopyDevices\n");
	return CFSetCreate(NULL, (const void **) devs, 1, NULL);
}

void se_IOHIDManagerRegisterDeviceMatchingCallback( IOHIDManagerRef manager, IOHIDDeviceCallback callback, void *context) {
	printf("IOHIDManagerRegisterDeviceMatchingCallback\n");
}

void se_IOHIDManagerRegisterDeviceRemovalCallback( IOHIDManagerRef manager, IOHIDDeviceCallback callback, void *context) {
	printf("IOHIDManagerRegisterDeviceMatchingCallback\n");
}



void se_IOHIDManagerSetDeviceMatchingMultiple( IOHIDManagerRef manager, CFArrayRef multiple) {
	printf("IOHIDManagerSetDeviceMatchingMultiple\n");
}


void se_IOHIDManagerUnscheduleFromRunLoop( IOHIDManagerRef manager, CFRunLoopRef runLoop, CFStringRef runLoopMode) {
	printf("IOHIDManagerUnscheduleFromRunLoop\n");
}

IOReturn se_IOHIDDeviceOpen( IOHIDDeviceRef device, IOOptionBits options) {
	printf("IOHIDDeviceOpen %p\n", (void *) device);
	return kIOReturnSuccess;
}

CFNumberRef makeUShort(unsigned short value) {
	return CFNumberCreate(NULL, kCFNumberShortType, &value);
}

CFTypeRef se_IOHIDDeviceGetProperty( IOHIDDeviceRef device, CFStringRef key) {
	printf("IOHIDDeviceGetProperty('%s')\n", CFStringGetCStringPtr(key, kCFStringEncodingMacRoman));
	if(CFStringCompare(key, CFSTR("VendorID"), 0) == 0) {
		return makeUShort(0x54c);
	} else if(CFStringCompare(key, CFSTR("ProductID"), 0) == 0) {
		return makeUShort(0x5c4);
	} else if(CFStringCompare(key, CFSTR("Transport"), 0) == 0) {
		return CFSTR("USB");
	} else if(CFStringCompare(key, CFSTR("VersionNumber"), 0) == 0) {
		return makeUShort(0x100);
	}
	return NULL;
}

IOReturn se_IOHIDDeviceGetReport( IOHIDDeviceRef device, IOHIDReportType reportType, CFIndex reportID, uint8_t *report, CFIndex *pReportLength) {
	printf("IOHIDDeviceGetReport(0x%x, %i)\n", (int) reportID, pReportLength == NULL ? 0 : (int) *pReportLength);
	if(reportID == 0x12) {
		uint8_t report12[] = {0x12, 0x8B, 0x09, 0x07, 0x6D, 0x66, 0x1C, 0x08, 0x25, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(report12));
		memcpy(report, report12, sizeof(report12));
	} else if(reportID == 0xa3) {
		uint8_t reporta3[] = {0xA3, 0x41, 0x75, 0x67, 0x20, 0x20, 0x33, 0x20, 0x32, 0x30, 0x31, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x37, 0x3A, 0x30, 0x31, 0x3A, 0x31, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x31, 0x03, 0x00, 0x00, 0x00, 0x49, 0x00, 0x05, 0x00, 0x00, 0x80, 0x03, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(reporta3));
		memcpy(report, reporta3, sizeof(reporta3));
	} else if(reportID == 0x02) {
		uint8_t report02[] = {0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87, 0x22, 0x7B, 0xDD, 0xB2, 0x22, 0x47, 0xDD, 0xBD, 0x22, 0x43, 0xDD, 0x1C, 0x02, 0x1C, 0x02, 0x7F, 0x1E, 0x2E, 0xDF, 0x60, 0x1F, 0x4C, 0xE0, 0x3A, 0x1D, 0xC6, 0xDE, 0x08, 0x00};
		assert(pReportLength != NULL && *pReportLength >= sizeof(report02));
		memcpy(report, report02, sizeof(report02));
	}
	return kIOReturnSuccess;
}

IOReturn se_IOHIDDeviceSetReport( IOHIDDeviceRef device, IOHIDReportType reportType, CFIndex reportID, const uint8_t *report, CFIndex reportLength) {
	printf("IOHIDDeviceSetReport\n");
	return kIOReturnSuccess;
}



@interface HIDRunner:NSObject
{
	CFRunLoopRef runLoop;
	CFStringRef runLoopMode;

	IOHIDReportCallback callback;
	void *context;

	uint8_t *report;
	CFIndex reportLength;

	uint64_t ticks;

	bool X, O, square, triangle, PS, touchpad, options, share, 
	L1, L2, L3, R1, R2, R3, dpadUp, dpadDown, dpadLeft, dpadRight;
	float leftX, leftY, rightX, rightY; // -1 to 1
	uint8_t uleftX, uleftY, urightX, urightY;

	bool keys[256], leftMouse, rightMouse;
	bool kicked, decayKicked;

	bool mouseMoved;
	NSPoint lastMouse;
	CFAbsoluteTime lastMouseTime;
	float mouseAccelX, mouseAccelY, mouseVelX, mouseVelY;
	float mouseDeltaX, mouseDeltaY;
	CFAbsoluteTime lastLeak;
	uint16_t gyroTimestamp;
}

// -(void)fakeDown:(int)code;
// -(void)fakeUp:(int)code;
-(void)tickpad:(int)code :(int)val;
+ (void)accumulateMouse:(NSEvent *)event;
@end



static HIDRunner *hid;

////
////
////
////
////
// 3/1/2020 Fetch by MiCkSoftware: Add gamepad wrapper



@interface GPadManager : NSObject 
+(void)gpadloop:(id)param;
-(void)start;
-(void)close;
@end

@implementation GPadManager

static int fd;

- (void) close {
	close(fd);
}

- (void) start {
		// char buf[10];
		// printf("GPAD Server: task launch\n");
		
		// sprintf(buf,"%d",getpid());
		// sprintf(buf,"%d",getpid());
		// if(mkfifo("/tmp/gpad-daemon-data",0660) == -1)
		// 		perror("mkfifo");
		// else 
		// 	printf("GPAD Server: pipe created : %s\n", buf);

		[NSThread detachNewThreadSelector:@selector(gpadloop:) toTarget:[GPadManager class] withObject:self];
}


+(void)gpadloop:(id)param{

	char rdbuf[50];
	int code,val;
	fd = open("/tmp/gpad-daemon-data",O_RDONLY);
	
	while (true) {

		while (read(fd, rdbuf, 50)) {

		if (strlen(rdbuf) > 0) {
			// printf("GPAD Server: has been entered : [%s] \n",rdbuf);
			int n = sscanf(rdbuf, "%d %d", &code, &val) ;
			if (n >0) {
				// printf("\t\t[%d][%d] \n",code, val);
				[hid tickpad:code :val];
			}
			sprintf(rdbuf, "%s", "\0");
			fflush(stdout);
		} 
		}
		
		usleep(10000);
	} 

	// printf("GPAD Server: task loop KILLED!\n");
}
@end





static GPadManager *gpadmanager;
////
////
////
////
////
////
////
////

#define MOUSESTEPS 10

#include "mapMeta.h"

static bool se_keyIsMapped(unsigned short code) {
	for(int i = 0; i < SE_NUM_MAPPED_KEYS; ++i)
		if(se_mappedKeys[i] == code)
			return true;
	return false;
}

/*
 * Current Remote Play carries its own keyboard/mouse -> controller mapping,
 * installed as an NSEvent local monitor. A local monitor runs before the
 * responder chain, so the app acts on a key *and* our swizzled keyDown: maps it
 * -- 'd' walks right and presses X at the same time.
 *
 * Wrapping the monitor lets us withhold exactly the inputs the .se file claims.
 * Returning the event (rather than nil) keeps it flowing down the responder
 * chain to HIDRunner; we simply never hand it to Remote Play's own handler.
 * Unmapped keys are passed through untouched, so menu shortcuts and text entry
 * still work.
 */
static id (*se_orig_addLocalMonitor)(id, SEL, NSEventMask, id (^)(NSEvent *));

static id se_addLocalMonitor(id self, SEL _cmd, NSEventMask mask, id (^handler)(NSEvent *)) {
	id (^filtered)(NSEvent *) = ^id (NSEvent *event) {
		switch([event type]) {
		case NSEventTypeKeyDown:
		case NSEventTypeKeyUp:
			if(se_keyIsMapped([event keyCode]))
				return event;
			break;
		case NSEventTypeLeftMouseDown:
		case NSEventTypeLeftMouseUp:
			if(SE_MAP_LEFT_MOUSE)
				return event;
			break;
		case NSEventTypeRightMouseDown:
		case NSEventTypeRightMouseUp:
			if(SE_MAP_RIGHT_MOUSE)
				return event;
			break;
		case NSEventTypeMouseMoved:
		case NSEventTypeLeftMouseDragged:
		case NSEventTypeRightMouseDragged:
			if(SE_MAP_MOUSELOOK)
				return event;
			break;
		default:
			break;
		}
		return handler(event);
	};
	return se_orig_addLocalMonitor(self, _cmd, mask, filtered);
}

/*
 * mouseMoved: is only delivered to the responder chain when the window opts in,
 * and Remote Play's windows do not. Without this, mouseLook silently does
 * nothing however the .se file is written.
 */
static void se_enableMouseMoved(void) {
	for(NSWindow *w in [NSApp windows])
		[w setAcceptsMouseMovedEvents:YES];
}

/*
 * Without capture, mouse look dies after a short movement: the pointer leaves
 * the Remote Play window, the events go to whatever is under it, and a local
 * monitor only sees events aimed at its own app. Disassociating the pointer
 * from the cursor keeps deltas flowing while the cursor stays put.
 *
 * Off until you press the capture key (mouseLook.captureKey, default escape),
 * so the cursor still works for signing in. Released automatically whenever the
 * app loses focus, so it is never possible to get stuck without a pointer.
 */
static bool se_captured = false;
static bool se_debugMouse = false;
static int se_skipMotion = 0;

/* Warping the cursor is itself reported back to us as a large mouse movement.
   Left alone that snaps the view hard every time we centre the pointer, so
   discard the event our own warp produces. */
static void se_warpTo(CGPoint p) {
	se_skipMotion = 1;
	CGWarpMouseCursorPosition(p);
}

/*
 * Warping the cursor opens a local-events suppression interval, during which
 * the window server drops real mouse/trackpad input. Combined with a
 * disassociated cursor that is indistinguishable from "capture works but
 * nothing moves", so explicitly permit hardware events throughout.
 */
static void se_permitLocalEvents(void) {
	CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
	if(src == NULL)
		return;
	CGEventSourceSetLocalEventsFilterDuringSuppressionState(src,
		kCGEventFilterMaskPermitAllEvents, kCGEventSuppressionStateSuppressionInterval);
	CGEventSourceSetLocalEventsFilterDuringSuppressionState(src,
		kCGEventFilterMaskPermitAllEvents, kCGEventSuppressionStateRemoteMouseDrag);
	CFRelease(src);
}

/* Window centre in CoreGraphics coordinates (origin top-left of the primary
   screen), which is what CGWarpMouseCursorPosition expects. */
static CGPoint se_windowCentre(void) {
	NSWindow *w = [NSApp keyWindow] ?: [[NSApp windows] firstObject];
	NSScreen *primary = [[NSScreen screens] firstObject];
	NSRect f = (w != nil) ? [w frame] : [[NSScreen mainScreen] frame];
	CGFloat flip = (primary != nil) ? [primary frame].size.height : 0;
	return CGPointMake(NSMidX(f), flip - NSMidY(f));
}

static void se_setCapture(bool on) {
	if(on == se_captured)
		return;
	se_captured = on;
	if(on) {
		se_permitLocalEvents();
		se_warpTo(se_windowCentre());
		CGDisplayHideCursor(kCGDirectMainDisplay);
		/* recenter mode leaves the cursor associated -- a trackpad only
		   produces deltas when the pointer genuinely moves, so we let it move
		   and warp it back to the centre before it can escape the window. */
		if(SE_CAPTURE_MODE_LOCK)
			CGAssociateMouseAndMouseCursorPosition(false);
	} else {
		if(SE_CAPTURE_MODE_LOCK)
			CGAssociateMouseAndMouseCursorPosition(true);
		CGDisplayShowCursor(kCGDirectMainDisplay);
	}
	NSLog(@"ShockEmu: mouse capture %s (%s mode)", on ? "ON" : "OFF",
		SE_CAPTURE_MODE_LOCK ? "lock" : "recenter");
}

/* Keep the pointer well inside the window so it can never wander out and stop
   delivering events to us. Warps are rare, so the artefacts are negligible. */
static void se_recentreIfDrifting(void) {
	NSWindow *w = [NSApp keyWindow];
	if(w == nil)
		return;
	NSRect f = [w frame];
	NSPoint p = [NSEvent mouseLocation];
	if(fabs(p.x - NSMidX(f)) > f.size.width * .3 ||
	   fabs(p.y - NSMidY(f)) > f.size.height * .3)
		se_warpTo(se_windowCentre());
}

static void se_installEventHooks(void) {
	se_debugMouse = getenv("SHOCKEMU_DEBUG_MOUSE") != NULL;

	Method m = class_getClassMethod([NSEvent class],
		@selector(addLocalMonitorForEventsMatchingMask:handler:));
	if(m != NULL) {
		se_orig_addLocalMonitor = (id (*)(id, SEL, NSEventMask, id (^)(NSEvent *)))
			method_getImplementation(m);
		method_setImplementation(m, (IMP) se_addLocalMonitor);
	} else
		NSLog(@"ShockEmu: could not hook addLocalMonitorForEventsMatchingMask:");

	if(SE_MAP_MOUSELOOK) {
		/* Our own monitor, so look keeps working while a mouse button is held
		   (AppKit sends mouseDragged:, not mouseMoved:, during a drag) and
		   regardless of whether the window accepts mouse-moved events. */
		se_orig_addLocalMonitor([NSEvent class],
			@selector(addLocalMonitorForEventsMatchingMask:handler:),
			NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged | NSEventMaskRightMouseDragged,
			^NSEvent * (NSEvent *event) {
				[HIDRunner accumulateMouse:event];
				return event;
			});

		/* Capture toggle. Consumed (nil) so Remote Play never sees the key. */
		se_orig_addLocalMonitor([NSEvent class],
			@selector(addLocalMonitorForEventsMatchingMask:handler:),
			NSEventMaskKeyDown | NSEventMaskFlagsChanged,
			^NSEvent * (NSEvent *event) {
				if([event keyCode] != SE_CAPTURE_KEY)
					return event;
				if([event type] == NSEventTypeFlagsChanged) {
					/* A modifier reports press and release through the same
					   event, so only act when it has just gone down. */
					if(([event modifierFlags] & SE_CAPTURE_MODIFIER) == 0)
						return event;
				}
				se_setCapture(!se_captured);
				return nil;
			});

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserverForName:NSWindowDidBecomeKeyNotification object:nil queue:nil
			usingBlock:^(NSNotification *note) {
				[(NSWindow *) [note object] setAcceptsMouseMovedEvents:YES];
			}];
		[nc addObserverForName:NSApplicationDidFinishLaunchingNotification object:nil queue:nil
			usingBlock:^(NSNotification *note) { se_enableMouseMoved(); }];
		[nc addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:nil
			usingBlock:^(NSNotification *note) { se_setCapture(false); }];
	}
}



#define SWAP(ocls, sel) do { \
	id rcls = NSClassFromString(@"_TtC10RemotePlay17RPWindowStreaming"); \
	SEL selector = @selector sel; \
	Method original = class_getInstanceMethod(rcls, selector); \
	Method new = class_getInstanceMethod(cls, selector); \
	method_exchangeImplementations(original, new); \
} while(0)

@implementation HIDRunner
+ (void)load {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		id cls = NSClassFromString(@"HIDRunner");
		se_installEventHooks();
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (keyDown:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (keyUp:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (mouseMoved:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (mouseDown:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (mouseUp:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (rightMouseDown:));
		SWAP(@"_TtC10RemotePlay17RPWindowStreaming", (rightMouseUp:));
	});
	////

}



- (id)initWithRunLoop:(CFRunLoopRef)_runLoop andMode:(CFStringRef)_mode {
	hid = self = [super init];
	runLoop = _runLoop;
	runLoopMode = _mode;
	ticks = 0;

	for(int i = 0; i < 256; ++i)
		keys[i] = false;

	gpadmanager = [GPadManager new];
	[gpadmanager start];

	return self;
}

- (void)registerCallback:(IOHIDReportCallback)cb withContext:(void *)ctx andReport:(uint8_t *)rep withLength:(CFIndex) repLen {
	callback = cb;
	context = ctx;
	report = rep;
	reportLength = repLen;
}

////
////
////
////
////
// 3/1/2020 Fetch by MiCkSoftware: Add gamepad wrapper
- (void)tickpad: (int)code :(int)val {
	uint8_t brep[] = {0x01, 0x7f, 0x81, 0x82, 0x7d, 0x08, 0x00, 0xb4, 0x00, 0x00, 0xc8, 0xad, 0xf9, 0x04, 0x00, 0xfe, 0xff, 0xfc, 0xff, 0xe5, 0xfe, 0xcb, 0x1f, 0x69, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x01, 0x63, 0x8b, 0x80, 0xc1, 0x2e, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00};
	PSReport *prep = (PSReport *) report;
	uint8_t dpad = 8;
	
	memcpy(report, brep, sizeof(brep));

	// printf("\t\t[%d][%d] \n",code, val);
	

	if (code ==57)
		dpad = val;

	if (code == 2) { X = (val == 1);}
	else if (code == 3) { O = (val == 1);}
	else if (code == 1) { square = (val == 1);}
	else if (code == 4) { triangle = (val == 1);}
	else if (code == 5) { L1 = (val == 1);}
	else if (code == 6) { R1 = (val == 1);}
	else if (code == 7) { L2 = (val == 1);}
	else if (code == 8) { R2 = (val == 1);}
	else if (code == 9) { share = (val == 1);}
	else if (code == 10) { options = (val == 1);}
	else if (code == 11) { L3 = (val == 1);}
	else if (code == 12) { R3 = (val == 1);}
	else if (code == 13) { PS = (val == 1);}
	else if (code == 48) { 
		uleftX = (uint8_t) fmin(fmax(val, 0), 255);
	} else if (code == 49) { 
		uleftY = (uint8_t) fmin(fmax(val, 0), 255);
	} else if (code == 50) { 
		urightX = (uint8_t) fmin(fmax(val, 0), 255);
	} else if (code == 53) { 
		urightY = (uint8_t) fmin(fmax(val, 0), 255);
	} 

	// NSLog(@"\t\t [%d] [%d]", code, val);

	prep->buttons1 = (triangle ? (1 << 7) : 0) | (O ? (1 << 6) : 0) | (X ? (1 << 5) : 0) | (square ? (1 << 4) : 0) | dpad;
	prep->buttons2 = (R3 ? (1 << 7) : 0) | (L3 ? (1 << 6) : 0) | (options ? (1 << 5) : 0) | (share ? (1 << 4) : 0) | 
		(R2 ? (1 << 3) : 0) | (L2 ? (1 << 2) : 0) | (R1 ? (1 << 1) : 0) | (L1 ? (1 << 0) : 0);
	prep->buttons3 = ((ticks << 2) & 0xFF) | (touchpad ? 2 : 0) | (PS ? 1 : 0);
	prep->left_trigger = L2 ? 255 : 0;
	prep->right_trigger = R2 ? 255 : 0;
	prep->left_x = uleftX;
	prep->left_y = uleftY;
	prep->right_x = urightX;
	prep->right_y = urightY;
	callback(context, kIOReturnSuccess, (void *)0xDEADBEEF, kIOHIDReportTypeInput, 0x01, report, 64);

	ticks++;

}
////
////
////
////
////

- (void)tick {
	uint8_t brep[] = {0x01, 0x7f, 0x81, 0x82, 0x7d, 0x08, 0x00, 0xb4, 0x00, 0x00, 0xc8, 0xad, 0xf9, 0x04, 0x00, 0xfe, 0xff, 0xfc, 0xff, 0xe5, 0xfe, 0xcb, 0x1f, 0x69, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1b, 0x00, 0x00, 0x01, 0x63, 0x8b, 0x80, 0xc1, 0x2e, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00};
	PSReport *prep = (PSReport *) report;

	memcpy(report, brep, sizeof(brep));

#if SE_MAP_MOUSELOOK && !SE_MOUSE_MODE_GYRO
	/*
	 * Spend the accumulated motion in proportion to the deflection actually
	 * emitted. Because d(accumulator)/dt = -deflection * drain, the integral of
	 * deflection -- which is what the console turns into rotation -- comes out
	 * as accumulator/drain regardless of how fast the swipe was or whether the
	 * stick saturated. Decaying by time instead made a slow swipe turn much
	 * further than a quick one covering the same distance.
	 */
	{
		CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
		float dt = (lastLeak > 0) ? fminf((float) (now - lastLeak), .1f) : .016f;
		float dx = fmaxf(-1.f, fminf(1.f, mouseDeltaX * (float) SE_MOUSE_SENSITIVITY));
		float dy = fmaxf(-1.f, fminf(1.f, mouseDeltaY * (float) SE_MOUSE_SENSITIVITY));
		float spendX = dx * (float) SE_MOUSE_DRAIN * dt;
		float spendY = dy * (float) SE_MOUSE_DRAIN * dt;

		if(se_debugMouse && (dx != 0 || dy != 0))
			NSLog(@"ShockEmu stick: (%.2f, %.2f)%s  banked (%.0f, %.0f)px",
				dx, dy, (fabsf(dx) >= .999f || fabsf(dy) >= .999f) ? "  PEGGED" : "",
				mouseDeltaX, mouseDeltaY);

		lastLeak = now;
		/* Never spend past zero, or the stick would flip sign on a long frame. */
		mouseDeltaX = (fabsf(spendX) >= fabsf(mouseDeltaX)) ? 0 : mouseDeltaX - spendX;
		mouseDeltaY = (fabsf(spendY) >= fabsf(mouseDeltaY)) ? 0 : mouseDeltaY - spendY;
	}
#endif

	[self mapKeys];
	
	// NSLog(@"leftX %f", leftX);

	uint8_t dpad = 8;
	if(dpadLeft) {
		if(dpadUp)
			dpad = 7;
		else if(dpadDown)
			dpad = 5;
		else
			dpad = 6;
	} else if(dpadRight) {
		if(dpadUp)
			dpad = 1;
		else if(dpadDown)
			dpad = 3;
		else
			dpad = 2;
	} else if(dpadUp)
		dpad = 0;
	else if(dpadDown)
		dpad = 4;
	prep->buttons1 = (triangle ? (1 << 7) : 0) | (O ? (1 << 6) : 0) | (X ? (1 << 5) : 0) | (square ? (1 << 4) : 0) | dpad;
	prep->buttons2 = (R3 ? (1 << 7) : 0) | (L3 ? (1 << 6) : 0) | (options ? (1 << 5) : 0) | (share ? (1 << 4) : 0) | 
		(R2 ? (1 << 3) : 0) | (L2 ? (1 << 2) : 0) | (R1 ? (1 << 1) : 0) | (L1 ? (1 << 0) : 0);
	prep->buttons3 = ((ticks << 2) & 0xFF) | (touchpad ? 2 : 0) | (PS ? 1 : 0);
	prep->left_trigger = L2 ? 255 : 0;
	prep->right_trigger = R2 ? 255 : 0;
	prep->left_x = (uint8_t) fmin(fmax(128 + leftX * 127, 0), 255);
	prep->left_y = (uint8_t) fmin(fmax(128 + leftY * 127, 0), 255);
	prep->right_x = (uint8_t) fmin(fmax(128 + rightX * 127, 0), 255);
	prep->right_y = (uint8_t) fmin(fmax(128 + rightY * 127, 0), 255);
#if SE_MAP_MOUSELOOK && SE_MOUSE_MODE_GYRO
	/*
	 * Gyro aiming. The DualShock reports angular *velocity*, which the console
	 * integrates into an angle -- so total rotation is proportional to total
	 * mouse distance no matter how fast the swipe was, and the view stops dead
	 * the instant the mouse does (velocity -> 0). No max-turn-rate ceiling, no
	 * banking, no glide: the three problems the thumbstick could not escape.
	 *
	 * The struct's int16 fields are misaligned against the wire format (the
	 * uint8 run before them forces a pad byte), so write raw little-endian at
	 * the true report offsets. Motion block: gyro 13/15/17, accel 19/21/23.
	 */
	{
		bool sent = (mouseDeltaX != 0 || mouseDeltaY != 0);
		float yawSrc   = mouseDeltaX * (float) SE_GYRO_SENS * (float) SE_GYRO_YAW_SIGN;
		float pitchSrc = mouseDeltaY * (float) SE_GYRO_SENS * (float) SE_GYRO_PITCH_SIGN;
		int yaw   = (int) fmaxf(-32767.f, fminf(32767.f, yawSrc));
		int pitch = (int) fmaxf(-32767.f, fminf(32767.f, pitchSrc));

		report[SE_GYRO_YAW_OFF]       = (uint8_t) (yaw & 0xFF);
		report[SE_GYRO_YAW_OFF + 1]   = (uint8_t) ((yaw >> 8) & 0xFF);
		report[SE_GYRO_PITCH_OFF]     = (uint8_t) (pitch & 0xFF);
		report[SE_GYRO_PITCH_OFF + 1] = (uint8_t) ((pitch >> 8) & 0xFF);

		/*
		 * The console integrates gyro as angle += rate * dt, where dt is the
		 * delta between consecutive report timestamps (DS4 units, ~5.33us).
		 * The original report kept this field static, so dt was always zero and
		 * no rotation ever integrated -- gyro was received and multiplied by
		 * nothing. Advance it a fixed step per report: each report is then one
		 * uniform timestep, so total angle comes out proportional to total
		 * mouse distance regardless of how fast reports actually arrive.
		 */
		gyroTimestamp += (uint16_t) SE_GYRO_TS_STEP;
		report[10] = (uint8_t) (gyroTimestamp & 0xFF);
		report[11] = (uint8_t) ((gyroTimestamp >> 8) & 0xFF);

		if(se_debugMouse && (mouseDeltaX != 0 || mouseDeltaY != 0))
			NSLog(@"ShockEmu gyro: yaw=%d pitch=%d ts=%u  from (%.0f, %.0f)px",
				yaw, pitch, (unsigned) gyroTimestamp, mouseDeltaX, mouseDeltaY);

		/* Angular velocity is a per-report sample: fully consumed each tick. */
		mouseDeltaX = mouseDeltaY = 0;
		/* Guarantee a trailing zero-velocity report so the console does not keep
		   integrating the last sample once the mouse stops. */
		if(sent)
			[self decayKick];
	}
#endif

	callback(context, kIOReturnSuccess, (void *)0xDEADBEEF, kIOHIDReportTypeInput, 0x01, report, 64);

	ticks++;
}

- (void)kick {
	
	if(kicked)
		return;
	kicked = true;
	CFRunLoopPerformBlock(runLoop, runLoopMode, ^void() {
		kicked = false;
		[self tick];
	});
	/* A block enqueued this way only runs the next time the run loop runs. If
	   it is asleep the tick waits for some unrelated event to wake it, which
	   shows up as inconsistent input lag. */
	CFRunLoopWakeUp(runLoop);
}

- (void)decayKick {
	if(decayKicked)
		return;
	decayKicked = true;
	CFRunLoopPerformBlock(runLoop, runLoopMode, ^void() {
		decayKicked = false;
		[self tick];
	});
	CFRunLoopWakeUp(runLoop);
}

#define JOYDECAY 5
#define DEADZONE .1

#define DOWN(key) keys[key]
- (void)mapKeys {
#include "mapKeys.h"
}


- (void)keyDown:(NSEvent *)event {
	//NSLog(@"down %i", [event keyCode]);
	hid->keys[[event keyCode]] = true;
	[hid kick];
}
- (void)keyUp:(NSEvent *)event {
	//NSLog(@"up %i", [event keyCode]);
	hid->keys[[event keyCode]] = false;
	[hid kick];
}

/*
 * Relative deltas, accumulated because several motion events can land between
 * ticks. deltaY is positive downwards, so flip it to the Y-up convention the
 * stick mapping uses; mouseLook.multY inverts it again if you want it the
 * other way round.
 */
+ (void)accumulateMouse:(NSEvent *)event {
	static NSTimeInterval lastStamp = -1;

	if(hid == nil)
		return;

	/* Our monitor and the responder chain both deliver the same event; without
	   this every movement counts twice. */
	if([event timestamp] == lastStamp)
		return;
	lastStamp = [event timestamp];

	if(se_skipMotion > 0) {
		se_skipMotion--;
		if(se_debugMouse)
			NSLog(@"ShockEmu mouse: discarded warp echo");
		return;
	}

	/* NSEvent's deltas are computed from how far the cursor moved, so they read
	   zero for a trackpad once the cursor is pinned. The CGEvent carries the
	   device's own deltas, which survive capture. */
	float dx = [event deltaX], dy = [event deltaY];
	CGEventRef ce = [event CGEvent];
	if(ce != NULL) {
		float cdx = (float) CGEventGetIntegerValueField(ce, kCGMouseEventDeltaX);
		float cdy = (float) CGEventGetIntegerValueField(ce, kCGMouseEventDeltaY);
		if(cdx != 0 || cdy != 0) {
			dx = cdx;
			dy = cdy;
		}
	}

	if(se_debugMouse)
		NSLog(@"ShockEmu mouse: NSEvent(%.1f, %.1f) CGEvent(%lld, %lld) -> using (%.1f, %.1f)",
			[event deltaX], [event deltaY],
			ce ? CGEventGetIntegerValueField(ce, kCGMouseEventDeltaX) : 0,
			ce ? CGEventGetIntegerValueField(ce, kCGMouseEventDeltaY) : 0, dx, dy);

	if(se_captured && !SE_CAPTURE_MODE_LOCK)
		se_recentreIfDrifting();

	hid->mouseDeltaX += dx;
	hid->mouseDeltaY += -dy;

	/*
	 * The stick caps at full deflection, so a swipe faster than the console can
	 * physically turn leaves motion banked up and the view keeps rotating after
	 * your finger stops. Cap the bank at maxGlide seconds' worth: a very fast
	 * swipe then turns less than its distance would suggest, which is far
	 * better than the view sliding on for a second afterwards.
	 */
	{
		float cap = (float) SE_MOUSE_DRAIN * (float) SE_MOUSE_MAXGLIDE;
		hid->mouseDeltaX = fmaxf(-cap, fminf(cap, hid->mouseDeltaX));
		hid->mouseDeltaY = fmaxf(-cap, fminf(cap, hid->mouseDeltaY));
	}
	hid->mouseMoved = true;
	/* Only kick. decayKick here would queue a second tick that decays the
	   value the first tick just set, cancelling most of the movement. */
	[hid kick];
}

- (void)mouseMoved:(NSEvent *)event {
	[HIDRunner accumulateMouse:event];
}
- (void)mouseDown:(NSEvent *)event {
	hid->leftMouse = true;
	[hid kick];
}
- (void)mouseUp:(NSEvent *)event {
	hid->leftMouse = false;
	[hid kick];
}
- (void)rightMouseDown:(NSEvent *)event {
	hid->rightMouse = true;
	[hid kick];
}
- (void)rightMouseUp:(NSEvent *)event {
	hid->rightMouse = false;
	[hid kick];
}
@end

void se_IOHIDManagerScheduleWithRunLoop( IOHIDManagerRef manager, CFRunLoopRef runLoop, CFStringRef runLoopMode) {
	printf("IOHIDManagerScheduleWithRunLoop\n");
	[[HIDRunner alloc] initWithRunLoop:runLoop andMode:runLoopMode];
}

void se_IOHIDDeviceScheduleWithRunLoop( IOHIDDeviceRef device, CFRunLoopRef runLoop, CFStringRef runLoopMode) {
	printf("IOHIDDeviceScheduleWithRunLoop\n");
}

void se_IOHIDDeviceRegisterInputReportCallback( IOHIDDeviceRef device, uint8_t *report, CFIndex reportLength, IOHIDReportCallback callback, void *context) {
	printf("IOHIDDeviceRegisterInputReportCallback\n");
	[hid registerCallback:callback withContext:context andReport:report withLength:reportLength];
}

DYLD_INTERPOSE(se_IOHIDManagerCreate, IOHIDManagerCreate)
DYLD_INTERPOSE(se_IOHIDManagerOpen, IOHIDManagerOpen)
DYLD_INTERPOSE(se_IOHIDManagerClose, IOHIDManagerClose)
DYLD_INTERPOSE(se_IOHIDManagerCopyDevices, IOHIDManagerCopyDevices)
DYLD_INTERPOSE(se_IOHIDManagerRegisterDeviceMatchingCallback, IOHIDManagerRegisterDeviceMatchingCallback)
DYLD_INTERPOSE(se_IOHIDManagerRegisterDeviceRemovalCallback, IOHIDManagerRegisterDeviceRemovalCallback)
DYLD_INTERPOSE(se_IOHIDManagerSetDeviceMatchingMultiple, IOHIDManagerSetDeviceMatchingMultiple)
DYLD_INTERPOSE(se_IOHIDManagerUnscheduleFromRunLoop, IOHIDManagerUnscheduleFromRunLoop)
DYLD_INTERPOSE(se_IOHIDManagerScheduleWithRunLoop, IOHIDManagerScheduleWithRunLoop)
DYLD_INTERPOSE(se_IOHIDDeviceOpen, IOHIDDeviceOpen)
DYLD_INTERPOSE(se_IOHIDDeviceGetProperty, IOHIDDeviceGetProperty)
DYLD_INTERPOSE(se_IOHIDDeviceGetReport, IOHIDDeviceGetReport)
DYLD_INTERPOSE(se_IOHIDDeviceSetReport, IOHIDDeviceSetReport)
DYLD_INTERPOSE(se_IOHIDDeviceScheduleWithRunLoop, IOHIDDeviceScheduleWithRunLoop)
DYLD_INTERPOSE(se_IOHIDDeviceRegisterInputReportCallback, IOHIDDeviceRegisterInputReportCallback)
