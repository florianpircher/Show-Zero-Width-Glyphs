//
//  SZWGReporterPlugin.m
//  Show Zero-Width Glyphs
//
//  Copyright 2021 Florian Pircher
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "SZWGReporterPlugin.h"

/// Draw layer options key for the current drawing scale.
static NSString * const kGlyphsDrawOptionScaleKey = @"Scale";
/// User default preferences key for the line color. The following colors are available: red = 0, orange = 1, brown = 2, yellow = 3, green = 4, blue = 7, purple = 8, pink = 9, gray = 10.
static NSString * const kLineColorKey = @"ShowZeroWidthGlyphsLineColor";
/// User default preferences key for the line alpha value. 1.0 is fully opaque; 0.0 is fully transparent.
static NSString * const kLineAlphaValueKey = @"ShowZeroWidthGlyphsLineAlphaValue";
/// User default preferences key for the line thickness. This thickness is added on all four sides of the layer box.
static NSString * const kLineThicknessKey = @"ShowZeroWidthGlyphsLineThickness";
/// User default preferences key for the maximum layer width for which the highlighting is applied.
static NSString * const kMaximumWidthKey = @"ShowZeroWidthGlyphsMaximumWidth";

@implementation SZWGReporterPlugin {
    NSViewController <GSGlyphEditViewControllerProtocol> *_editViewController;
    NSColor *lineColor;
    CGFloat lineAlphaValue;
    CGFloat lineThickness;
    int maximumWidth;
}

+ (void)initialize {
    if (self == [SZWGReporterPlugin class]) {
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            kLineColorKey: @8,
            kLineAlphaValueKey: @0.5,
            kLineThicknessKey: @1.0,
            kMaximumWidthKey: @0,
        }];
    }
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self reloadPreferencesFromUserDefaults];
        
        NSUserDefaultsController *controller = NSUserDefaultsController.sharedUserDefaultsController;
        [controller addObserver:self
                     forKeyPath:[@"values." stringByAppendingString:kLineColorKey]
                        options:NSKeyValueObservingOptionNew
                        context:nil];
        [controller addObserver:self
                     forKeyPath:[@"values." stringByAppendingString:kLineAlphaValueKey]
                        options:NSKeyValueObservingOptionNew
                        context:nil];
        [controller addObserver:self
                     forKeyPath:[@"values." stringByAppendingString:kLineThicknessKey]
                        options:NSKeyValueObservingOptionNew
                        context:nil];
        [controller addObserver:self
                     forKeyPath:[@"values." stringByAppendingString:kMaximumWidthKey]
                        options:NSKeyValueObservingOptionNew
                        context:nil];
    }
    
    return self;
}

- (void)dealloc {
    NSUserDefaultsController *controller = NSUserDefaultsController.sharedUserDefaultsController;
    [controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:kLineColorKey]];
    [controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:kLineAlphaValueKey]];
    [controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:kLineThicknessKey]];
    [controller removeObserver:self forKeyPath:[@"values." stringByAppendingString:kMaximumWidthKey]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == NSUserDefaultsController.sharedUserDefaultsController) {
        [self reloadPreferencesFromUserDefaults];
        [_editViewController redraw];
    }
}

/// Updates all property values with the current values from their user defaults storage.
- (void)reloadPreferencesFromUserDefaults {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    
    int lineColorId = (int)[defaults integerForKey:kLineColorKey];
    
    switch (lineColorId) {
    case 0: lineColor = NSColor.systemRedColor; break;
    case 1: lineColor = NSColor.systemOrangeColor; break;
    case 2: lineColor = NSColor.systemBrownColor; break;
    case 3: lineColor = NSColor.systemYellowColor; break;
    case 4: lineColor = NSColor.systemGreenColor; break;
    case 7: lineColor = NSColor.systemBlueColor; break;
    case 8: lineColor = NSColor.systemPurpleColor; break;
    case 9: lineColor = NSColor.systemPinkColor; break;
    default: lineColor = NSColor.systemGrayColor; break;
    }
    
    lineAlphaValue = [defaults doubleForKey:kLineAlphaValueKey];
    lineThickness = [defaults doubleForKey:kLineThicknessKey];
    maximumWidth = (int)[defaults integerForKey:kMaximumWidthKey];
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSString *)title {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return NSLocalizedStringFromTableInBundle(@"Zero-Width Glyphs", nil, bundle, @"Title of the menu item to activate the plugin");
}

- (NSString *)keyEquivalent {
    return nil;
}

- (NSEventModifierFlags)modifierMask {
    return 0;
}

- (void)drawBackgroundForLayer:(GSLayer *)layer options:(NSDictionary *)options {
    if (layer.width <= maximumWidth) {
        [self drawBackgroundForZeroWidthLayer:layer options:options];
    }
}

- (void)drawBackgroundForInactiveLayer:(GSLayer *)layer options:(NSDictionary *)options {
    if (layer.width <= maximumWidth) {
        [self drawBackgroundForZeroWidthLayer:layer options:options];
    }
}

- (void)drawBackgroundForZeroWidthLayer:(GSLayer *)layer options:(NSDictionary *)options {
    CGFloat scale = [options[kGlyphsDrawOptionScaleKey] doubleValue];
    CGFloat offset = lineThickness / scale;
    NSRect markRect = NSMakeRect(-offset, layer.descender - offset, layer.width + 2 * offset, -layer.descender + layer.ascender + 2 * offset);
    [[lineColor colorWithAlphaComponent:lineAlphaValue] set];
    [NSBezierPath fillRect:markRect];
}

- (BOOL)needsExtraMainOutlineDrawingForInactiveLayer:(GSLayer *)layer {
    return YES;
}

- (void)setController:(NSViewController <GSGlyphEditViewControllerProtocol>*)controller {
    _editViewController = controller;
}

@end
