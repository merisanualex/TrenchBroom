//
//  PreferencesWindowController.h
//  TrenchBroom
//
//  Created by Kristian Duske on 28.07.11.
//  Copyright 2011 TU Berlin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreferencesManager;

@interface PreferencesController : NSWindowController {
    IBOutlet NSTextField* quakePathTextField;
    IBOutlet NSPopUpButton* quakeExecutablePopUp;
}

+ (PreferencesController *)sharedPreferences;

- (IBAction)chooseQuakePath:(id)sender;
- (PreferencesManager *)preferences;

@end
