//
//  RNFrostedMenu.h
//  RNFrostedMenu
//
//  Created by Ryan Nystrom on 8/13/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//
//  Original Dribbble shot by Jakub Antalik
//  http://dribbble.com/shots/1194205-Sidebar-calendar-animation
//

#import <UIKit/UIKit.h>

@class RNFrostedSidebar;

@protocol RNFrostedSidebarDelegate <NSObject>
@optional
- (void)sidebar:(RNFrostedSidebar *)sidebar willShowOnScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(RNFrostedSidebar *)sidebar didShowOnScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(RNFrostedSidebar *)sidebar willDismissFromScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(RNFrostedSidebar *)sidebar didDismissFromScreenAnimated:(BOOL)animatedYesOrNo;
- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index;
- (void)sidebar:(RNFrostedSidebar *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index;
@end

@interface RNFrostedSidebar : UIViewController

+ (instancetype)visibleSidebar;

// The width of the sidebar
// Default 150
@property (nonatomic, assign) CGFloat width;

// Access the view that contains the menu items
@property (nonatomic, strong, readonly) UIScrollView *contentView;

// Toggle displaying the sidebar on the right side of the device
// Default NO
@property (nonatomic, assign) BOOL showFromRight;

// The duration of the show and hide animations
// Default 0.25
@property (nonatomic, assign) CGFloat animationDuration;

// The dimension for each item view, not including padding
// Default {75, 75}
@property (nonatomic, assign) CGSize itemSize;

// The color to tint the blur effect
// Default white: 0.2, alpha: 0.73
@property (nonatomic, strong) UIColor *tintColor;

// The background color for each item view
// NOTE: set using either colorWithWhite:alpha or colorWithRed:green:blue:alpha
// Default white: 1, alpha 0.25
@property (nonatomic, strong) UIColor *itemBackgroundColor;

// The width of the colored border for selected item views
// Default 2
@property (nonatomic, assign) NSUInteger borderWidth;

// An optional delegate to respond to interaction events
@property (nonatomic, weak) id <RNFrostedSidebarDelegate> delegate;

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors;
- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices;
- (instancetype)initWithImages:(NSArray *)images;

- (void)show;
- (void)showAnimated:(BOOL)animated;
- (void)showInViewController:(UIViewController *)controller animated:(BOOL)animated;

- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

@end
