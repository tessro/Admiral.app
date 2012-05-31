//
//  ADAppDelegate.h
//  Admiral
//
//  Created by Paul Rosania on 5/25/12.
//  Copyright (c) 2012 Paul Rosania. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

typedef struct bounds {
    int left;
    int right;
    int top;
    int bottom;
} edges_t;

enum {
    kADKeyH = 4,
    kADKeyJ = 38,
    kADKeyK = 40,
    kADKeyL = 37,
};

enum {
    kADDirectionUp = 0,
    kADDirectionRight = (1 << 0),
    kADDirectionDown = (1 << 1),
    kADDirectionLeft = (1 << 2),
};

@interface ADAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
}

@property (assign) IBOutlet NSWindow *window;

- (void)moveFocus:(int)direction;

@end
