//
//  MapView3D.m
//  TrenchBroom
//
//  Created by Kristian Duske on 15.03.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MapView3D.h"
#import <OpenGl/gl.h>
#import <OpenGL/glu.h>
#import "Renderer.h"
#import "Camera.h"
#import "TextureManager.h"
#import "InputManager.h"
#import "SelectionManager.h"
#import "MapWindowController.h"
#import "MapDocument.h"
#import "Options.h"
#import "Grid.h"
#import "EntityDefinitionManager.h"
#import "EntityDefinition.h"
#import "PreferencesManager.h"

@interface MapView3D (private)

- (void)preferencesDidChange:(NSNotification *)notification;

@end

@implementation MapView3D (private)

- (void)preferencesDidChange:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

@end

@implementation MapView3D

- (BOOL)wantsPeriodicDraggingUpdates {
    return NO;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    [[self openGLContext] makeCurrentContext];
    
    InputManager* inputManager = [[[self window] windowController] inputManager];
    return [inputManager handleDraggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    [[self openGLContext] makeCurrentContext];

    InputManager* inputManager = [[[self window] windowController] inputManager];
    return [inputManager handleDraggingUpdated:sender];
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleDraggingEnded:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleDraggingExited:sender];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    return [inputManager prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    return [inputManager performDragOperation:sender];
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager concludeDragOperation:sender];
}

- (void)rendererChanged:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)gridChanged:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    PreferencesManager* preferences = [PreferencesManager sharedManager];
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(preferencesDidChange:) name:DefaultsDidChange object:preferences];
    
    [self registerForDraggedTypes:[NSArray arrayWithObject:EntityDefinitionType]];
}

- (BOOL)becomeFirstResponder {
    if ([super becomeFirstResponder]) {
        NSPoint base = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
        NSPoint point = [self convertPointFromBase:base];
        if (NSPointInRect(point, [self visibleRect])) {
            double timestamp = (double)(AbsoluteToDuration(UpTime())) / 1000.0;
            [self mouseEntered:[NSEvent enterExitEventWithType:NSMouseEntered 
                                                      location:base 
                                                 modifierFlags:[NSEvent modifierFlags] 
                                                     timestamp:timestamp windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] eventNumber:0 trackingNumber:0 userData:NULL]];
        }
        [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (BOOL)resignFirstResponder {
    if ([super resignFirstResponder]) {
        NSPoint base = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
        NSPoint point = [self convertPointFromBase:base];
        if (NSPointInRect(point, [self visibleRect])) {
            double timestamp = (double)(AbsoluteToDuration(UpTime())) / 1000.0;
            [self mouseExited:[NSEvent enterExitEventWithType:NSMouseExited 
                                                      location:base 
                                                 modifierFlags:[NSEvent modifierFlags] 
                                                     timestamp:timestamp windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] eventNumber:0 trackingNumber:0 userData:NULL]];
        }
        [self setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}

- (void)setup {
    MapWindowController* controller = [[self window] windowController];
    
    renderer = [[Renderer alloc] initWithWindowController:controller];
    options = [[controller options] retain];
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(rendererChanged:) name:RendererChanged object:renderer];
    [center addObserver:self selector:@selector(gridChanged:) name:GridChanged object:[options grid]];

    mouseTracker = [[NSTrackingArea alloc] initWithRect:[self visibleRect] options:NSTrackingActiveWhenFirstResponder | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    [self addTrackingArea:mouseTracker];
}

-  (void)updateTrackingAreas {
    if (mouseTracker != nil) {
        [self removeTrackingArea:mouseTracker];
        [mouseTracker release];
    }
    mouseTracker = [[NSTrackingArea alloc] initWithRect:[self visibleRect] options:NSTrackingActiveWhenFirstResponder | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    [self addTrackingArea:mouseTracker];
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    if (![inputManager handleKeyDown:theEvent sender:self])
        [super keyDown:theEvent];
}
 
- (void)flagsChanged:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleFlagsChanged:theEvent sender:self];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleLeftMouseDragged:theEvent sender:self];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleMouseMoved:theEvent sender:self];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleMouseEntered:theEvent sender:self];
}

- (void)mouseExited:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleMouseExited:theEvent sender:self];
}

- (void)mouseDown:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleLeftMouseDown:theEvent sender:self];
}

- (void)mouseUp:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleLeftMouseUp:theEvent sender:self];
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleRightMouseDragged:theEvent sender:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleRightMouseDown:theEvent sender:self];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleRightMouseUp:theEvent sender:self];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleScrollWheel:theEvent sender:self];
}

- (void)beginGestureWithEvent:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleBeginGesture:theEvent sender:self];
}

- (void)endGestureWithEvent:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleEndGesture:theEvent sender:self];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent {
    InputManager* inputManager = [[[self window] windowController] inputManager];
    [inputManager handleMagnify:theEvent sender:self];
}

- (void) drawRect:(NSRect)dirtyRect {
    NSWindow* window = [self window];
    if (window != nil) {
        MapWindowController* windowController = [window windowController];
        if (windowController != nil) {
            NSAssert([self openGLContext] == [NSOpenGLContext currentContext], @"open GL context is not current");
            
            glClearColor(backgroundColor[0], backgroundColor[1], backgroundColor[2], 0);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            Camera* camera = [windowController camera];
            [camera updateView:[self visibleRect]];
            [renderer render];
            
            [[self openGLContext] flushBuffer];
        }
    }
}

- (Renderer *)renderer {
    return renderer;
}

- (NSMenu *)pointEntityMenu {
    return pointEntityMenu;
}

- (NSMenu *)brushEntityMenu {
    return brushEntityMenu;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self openGLContext] makeCurrentContext]; // make sure we don't delete OpenGL objects that are not ours
    [renderer release];
    [options release];
    if (mouseTracker != nil) {
        [self removeTrackingArea:mouseTracker];
        [mouseTracker release];
    }
    [super dealloc];
}

@end
