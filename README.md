RNFrostedSidebar
===========

Add your own Control Center-esque UI to your app to work as navigation or even toggle different settings. Blend right into the new iOS 7 design with animated blurs, flat design, and custom animations.

This project is [another](https://github.com/rnystrom/RNRippleTableView) UI control built after finding some [inspiration](http://dribbble.com/shots/1194205-Sidebar-calendar-animation) on Dribbble. The original design was created by [Jakub Antalik](http://dribbble.com/antalik/click?type=twitter).

<p align="center"><img title="Open and close animation" src="https://raw.github.com/rnystrom/RNFrostedMenu/master/images/open.gif"/></p>

You'll notice that this control's use of blur does not match Jakub's original design exactly. In the original design the background of the buttons is blurred, while the overlay of the control is simply shaded. There have [been](https://github.com/alexdrone/ios-realtimeblur) [attempts](https://github.com/JagCesar/iOS-blur) at recreating this effect, but it is [rumored](http://stackoverflow.com/a/17299759/940936) that live-blurring takes place at a much lower level on the GPU and there would be security concerns were we to have access.

Apple is being a little deceptive with their use of blurring in iOS 7. Bottom line, **don't animate blurs** in your designs. 

If you examine the source of this project you'll see that I'm actually [cheating](https://github.com/rnystrom/RNFrostedSidebar/blob/master/RNFrostedSidebar.m#L371) to get the blur layer to animate overtop the original view.

<p align="center"><img title="Money shot" src="https://raw.github.com/rnystrom/RNFrostedMenu/master/images/click.gif"/></p>

## Installation ##

The preferred method of installation is with [CocoaPods](http://cocoapods.org/). Just add this line to your Podfile.

```
pod 'RNFrostedSidebar', '~> 0.1.0'
```

Or if you want to install manually, drag and drop the <code>RNFrostedSidebar</code> .h and .m files into your project. To get this working, you'll need to include the following frameworks in **Link Binary with Libraries**:

- QuartzCore
- Accelerate

## Usage ##

The simplest usage is to create a list of images, initialize a <code>RNFrostedSidebar</code> object, then call the <code>-show</code> method.

```objc
NSArray *images = @[
                    [UIImage imageNamed:@"gear"],
                    [UIImage imageNamed:@"globe"],
                    [UIImage imageNamed:@"profile"],
                    [UIImage imageNamed:@"star"]
                    ];

RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:images];
callout.delegate = self;
[callout show];
```

## Customization

I've exposed a healthy amount of options for you to customize the appearance and animation of the control.

```objc
- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices;
```

Use the parameter <code>selectedIndices</code> to add pre-selected options. Without using the init method below there wont be any visualization of selection. But, you will get the proper enabled/disabled BOOL in the delegate <code>-sidebar:didEnable:itemAtIndex:</code> method.

```objc
- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors;
```

Use the parameter <code>borderColors</code> to add border effect animations when selecting and deselecting a view.

```objc
@property (nonatomic, assign) CGFloat width;
```

The width of the blurred region. Default 150.

```objc
@property (nonatomic, assign) BOOL showFromRight;
```

Toggle showing the control from the right side of the device. Default NO.

```objc
@property (nonatomic, assign) CGFloat animationDuration;
```

The duration of the show and dismiss animations. Default 0.25.

```objc
@property (nonatomic, assign) CGSize itemSize;
```

The size of the item views. Default is width: 75, height: 75.

```objc
@property (nonatomic, strong) UIColor *tintColor;
```

The tint color of the blur. This can be a tricky property to set. I recommend using the provided alpha. Avoid using solid colors with an alpha of 1. Default white: 0.2, alpha: 0.73.

```objc
@property (nonatomic, strong) UIColor *itemBackgroundColor;
```

The background color for item views. **Note:** This property must be set with either <code>colorWithWhite:alpha</code> or <code>colorWithRed:green:blue:alpha</code> or it will crash. This is for highlight effects on tapping so the control can derive a darker background when highlighted. Default white: 1, alpha 0.25.

```objc
@property (nonatomic, assign) NSUInteger borderWidth;
```

The border width for item views. Default 2.

```objc
@property (nonatomic, weak) id <RNFrostedSidebarDelegate> delegate;
```

An optional delegate to respond to selection of item views. The two optional delegate methods are:

```objc
- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index;
- (void)sidebar:(RNFrostedSidebar *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index;
```

## Credits

UI Control structure and View Controller containment practices adopted from [Matthias Tretter](https://github.com/myell0w).

Sample icons provided by [Pixeden](http://www.pixeden.com/media-icons/tab-bar-icons-ios-7-vol2).

The blur algorithm comes from WWDC 2013's session 208, "What's New in iOS User Interface Design".

## Apps

If you've used this project in a live app, please <a href="mailTo:rnystrom@whoisryannystrom.com">let me know</a>! Nothing makes me happier than seeing someone else take my work and go wild with it.

## Contact

* [@nystrorm](https://twitter.com/_ryannystrom) on Twitter
* [@rnystrom](https://github.com/rnystrom) on Github
* <a href="mailTo:rnystrom@whoisryannystrom.com">rnystrom [at] whoisryannystrom [dot] com</a>

## License

See [LICENSE](https://github.com/rnystrom/RNFrostedSidebar/blob/master/LICENSE).
