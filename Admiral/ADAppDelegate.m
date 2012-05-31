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
    edges_t sourceEdges;
    BOOL sourceWindowFound = NO;
    
    pid_t candidatePid = 0;
    CGWindowID candidateWindowId = 0;
    edges_t candidateEdges;
    
    if (direction == kADDirectionUp) {
        candidateEdges.left = candidateEdges.right = 0;
        candidateEdges.top = candidateEdges.bottom = -INT_MAX;
    } else if (direction == kADDirectionRight) {
        candidateEdges.left = candidateEdges.right = INT_MAX;
        candidateEdges.top = candidateEdges.bottom = 0;
    } else if (direction == kADDirectionDown) {
        candidateEdges.left = candidateEdges.right = 0;
        candidateEdges.top = candidateEdges.bottom = INT_MAX;
    } else { // left
        candidateEdges.left = candidateEdges.right = -INT_MAX;
        candidateEdges.top = candidateEdges.bottom = 0;
    }
    
    for (int i = 0; i < CFArrayGetCount(windows); i++) {
        CFDictionaryRef window = CFArrayGetValueAtIndex(windows, i);

        int layer;
        CFNumberRef layerRef = CFDictionaryGetValue(window, kCGWindowLayer);
        CFNumberGetValue(layerRef, kCFNumberIntType, &layer);

        CGRect bounds;
        CFDictionaryRef boundsDict = CFDictionaryGetValue(window, kCGWindowBounds);
        CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds);
        
        // This is easier to understand when we're looping
        edges_t currentEdges;
        currentEdges.top    = bounds.origin.y;
        currentEdges.bottom = bounds.origin.y + bounds.size.height;
        currentEdges.left   = bounds.origin.x;
        currentEdges.right  = bounds.origin.x + bounds.size.width;
        
        pid_t pid;
        CFNumberRef pidRef = CFDictionaryGetValue(window, kCGWindowOwnerPID);
        CFNumberGetValue(pidRef, kCFNumberSInt32Type, &pid);
        
        CGWindowID windowId;
        CFNumberRef windowIdRef = CFDictionaryGetValue(window, kCGWindowNumber);
        CFNumberGetValue(windowIdRef, kCGWindowIDCFNumberType, &windowId);
        
        if (layer == 0) { // Layer zero is where real windows live
            if (!sourceWindowFound) { // The first window in the layer is topmost
                memcpy(&sourceEdges, &currentEdges, sizeof(edges_t));
                sourceWindowFound = YES;
                NSLog(@"[source] (%0.0f, %0.0f) %0.0fx%0.0f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
            } else {
                NSLog(@"[candidate] (%0.0f, %0.0f)\t%0.0fx%0.0f\t [pid=%i]", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, pid);
                
                // The current selection algorithm is very simple (and has a variety of flaws):
                // 1. Is the closest edge past the perimeter of our window? (Only navigate to non-overlapping windows.)
                // 2. Is the closest edge closer than our previous candidate?
                
                if (direction == kADDirectionUp) {
                    if (currentEdges.bottom <= sourceEdges.top && currentEdges.bottom > candidateEdges.bottom) {
                        memcpy(&candidateEdges, &currentEdges, sizeof(edges_t));
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else if (direction == kADDirectionRight) {
                    if (currentEdges.left >= sourceEdges.right && currentEdges.left < candidateEdges.left) {
                        memcpy(&candidateEdges, &currentEdges, sizeof(edges_t));
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else if (direction == kADDirectionDown) {
                    if (currentEdges.top >= sourceEdges.bottom && currentEdges.top < candidateEdges.top) {
                        memcpy(&candidateEdges, &currentEdges, sizeof(edges_t));
                        candidatePid = pid;
                        candidateWindowId = windowId;
                    }
                } else { // left
                    if (currentEdges.right <= sourceEdges.left && currentEdges.right > candidateEdges.right) {
                        memcpy(&candidateEdges, &currentEdges, sizeof(edges_t));
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
                if (candidateEdges.left == position.x && candidateEdges.top == position.y) {
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
