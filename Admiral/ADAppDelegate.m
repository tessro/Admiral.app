//
//  ADAppDelegate.m
//  Admiral
//
//  Created by Paul Rosania on 5/25/12.
//  Copyright (c) 2012 Paul Rosania. All rights reserved.
//

#import "ADAppDelegate.h"

@implementation ADAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self registerHotKeys];
}

-(void)awakeFromNib {
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"A"];
    [statusItem setHighlightMode:YES];
}

-(void)registerHotKeys
{	
    EventHotKeyRef gMyHotKeyRef;
    EventHotKeyID leftHotKeyID;
    EventHotKeyID rightHotKeyID;
    EventHotKeyID upHotKeyID;
    EventHotKeyID downHotKeyID;

    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;	
 	
    InstallApplicationEventHandler(&OnHotKeyEvent, 1, &eventType, self, NULL);
 	
    leftHotKeyID.signature = 'adm1';
    leftHotKeyID.id = kADDirectionLeft;
    RegisterEventHotKey(kADKeyH, cmdKey | controlKey, leftHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);	
 	
    downHotKeyID.signature = 'adm2';
    downHotKeyID.id = kADDirectionDown;
    RegisterEventHotKey(kADKeyJ, cmdKey | controlKey, downHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);	
 	
    upHotKeyID.signature = 'adm3';
    upHotKeyID.id = kADDirectionUp;
    RegisterEventHotKey(kADKeyK, cmdKey | controlKey, upHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);	
 	
    rightHotKeyID.signature = 'adm4';
    rightHotKeyID.id = kADDirectionRight;
    RegisterEventHotKey(kADKeyL, cmdKey | controlKey, rightHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
}

OSStatus OnHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    ADAppDelegate *delegate = (ADAppDelegate*)userData;
    
    EventHotKeyID hkID;
 	GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkID), NULL, &hkID);
    
    switch (hkID.id) {
        case kADDirectionUp:
            [delegate moveFocus:kADDirectionUp];
 			break;
        case kADDirectionRight:
            [delegate moveFocus:kADDirectionRight];
 			break;
        case kADDirectionDown:
            [delegate moveFocus:kADDirectionDown];
 			break;
         case kADDirectionLeft:
            [delegate moveFocus:kADDirectionLeft];
 			break;
    }
    
    return noErr;
}

- (void)moveFocus:(int)direction {
    // Insert code here to initialize your application
    CGWindowListOption option = kCGWindowListOptionOnScreenOnly | \
                                kCGWindowListExcludeDesktopElements | \
                                kCGWindowListOptionIncludingWindow;
    
    CFArrayRef windows = CGWindowListCopyWindowInfo(option, kCGNullWindowID);
    CGRect sourceWindow;
    BOOL sourceWindowFound = NO;
    
    pid_t candidatePid = 0;
    CGWindowID candidateWindowId = 0;
    int candidateX, candidateY;
    
    if (direction == kADDirectionUp) {
        candidateX = 0;
        candidateY = -INT_MAX;
    } else if (direction == kADDirectionRight) {
        candidateX = INT_MAX;
        candidateY = 0;
    } else if (direction == kADDirectionDown) {
        candidateX = 0;
        candidateY = INT_MAX;
    } else { // left
        candidateX = -INT_MAX;
        candidateY = 0;
    }
    
    for (int i = 0; i < CFArrayGetCount(windows); i++) {
        CFDictionaryRef window = CFArrayGetValueAtIndex(windows, i);

        int layer;
        CFNumberRef layerRef = CFDictionaryGetValue(window, kCGWindowLayer);
        CFNumberGetValue(layerRef, kCFNumberIntType, &layer);

        CGRect bounds;
        CFDictionaryRef boundsDict = CFDictionaryGetValue(window, kCGWindowBounds);
        CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds);
        
        pid_t pid;
        CFNumberRef pidRef = CFDictionaryGetValue(window, kCGWindowOwnerPID);
        CFNumberGetValue(pidRef, kCFNumberSInt32Type, &pid);
        
        CGWindowID windowId;
        CFNumberRef windowIdRef = CFDictionaryGetValue(window, kCGWindowNumber);
        CFNumberGetValue(windowIdRef, kCGWindowIDCFNumberType, &windowId);
        
        if (layer == 0) { // Layer zero is where real windows live
            if (!sourceWindowFound) { // The first window in the layer is topmost
                memcpy(&sourceWindow, &bounds, sizeof(CGRect));
                sourceWindowFound = YES;
                NSLog(@"[source] (%0.0f, %0.0f) %0.0fx%0.0f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
            } else {
                NSLog(@"[candidate] (%0.0f, %0.0f)\t%0.0fx%0.0f\t [pid=%i]", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, pid);
                
                if (direction == kADDirectionUp) {
                    if (bounds.origin.y < sourceWindow.origin.y && bounds.origin.y > candidateY) {
                        candidateX = bounds.origin.x;
                        candidateY = bounds.origin.y;
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else if (direction == kADDirectionRight) {
                    if (bounds.origin.x > sourceWindow.origin.x && bounds.origin.x < candidateX) {
                        candidateX = bounds.origin.x;
                        candidateY = bounds.origin.y;
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else if (direction == kADDirectionDown) {
                    if (bounds.origin.y > sourceWindow.origin.y && bounds.origin.y < candidateY) {
                        candidateX = bounds.origin.x;
                        candidateY = bounds.origin.y;
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else { // left
                    if (bounds.origin.x < sourceWindow.origin.x && bounds.origin.x > candidateX) {
                        candidateX = bounds.origin.x;
                        candidateY = bounds.origin.y;
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                }
            }
        }
    }
    
    CFRelease(windows);
    
    if (candidatePid) {
        AXUIElementRef axApp = AXUIElementCreateApplication(candidatePid);
        
        CFArrayRef appWindows;
        AXUIElementRef targetWindow;
        
        AXError err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute, (CFTypeRef*)&appWindows);
        
        if (!err) {
            for (int i = 0; i < CFArrayGetCount(appWindows); i++) {
                AXUIElementRef window = CFArrayGetValueAtIndex(appWindows, i);
                
                CGPoint position;
                AXValueRef positionRef;
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute, (CFTypeRef*)&positionRef);
                AXValueGetValue(positionRef, kAXValueCGPointType, &position);
                
                CGSize size;
                AXValueRef sizeRef;
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute, (CFTypeRef*)&sizeRef);
                AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
                if (candidateX == position.x && candidateY == position.y) {
                    targetWindow = window;
                    break;
                }
                
                CFRelease(positionRef);
                CFRelease(sizeRef);
                CFRelease(window);
            }
            
            if (targetWindow) {
                ProcessSerialNumber	psn	= {0, 0};
                AXUIElementPerformAction(targetWindow, kAXRaiseAction);
                
                if (GetProcessForPID(candidatePid, &psn) == noErr) {
                    SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly);
                    
                    // Note: this returns error -25200 for Chrome windows :(
                    AXUIElementSetAttributeValue(targetWindow, kAXMainAttribute, kCFBooleanTrue);
                }
            }
        }
        
        CFRelease(axApp);
    }
}

@end
