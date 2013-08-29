RNFrostedSidebar
===========

Add your own Control Center-esque UI to your app to work as navigation or even toggle different settings. Blend right into the new iOS 7 design with animated blurs, flat design, and custom animations.

This project is [another](https://github.com/rnystrom/RNRippleTableView) UI control built after finding some [inspiration](http://dribbble.com/shots/1194205-Sidebar-calendar-animation) on Dribbble. The original design was created by [Jakub Antalik](http://dribbble.com/antalik/click?type=twitter).

<p align="center"><img title="Open and close animation" src="https://dl.dropboxusercontent.com/u/6715236/open.gif"/></p>

You'll notice that this control's use of blur does not match Jakub's original design exactly. In the original design the background of the buttons is blurred, while the overlay of the control is simply shaded. There have [been](https://github.com/alexdrone/ios-realtimeblur) [attempts](https://github.com/JagCesar/iOS-blur) at recreating

Apple is being a little deceptive with their use of blurring in iOS 7. Bottom line, **don't animate blurs** in your designs. 

If you examine the source of this project you'll see that I'm actually cheating to get the blur layer to animate overtop the original view.

<p align="center"><img title="Money shot" src="https://dl.dropboxusercontent.com/u/6715236/click.gif"/></p>

## Installation ##

The preferred method of installation is with [CocoaPods](http://cocoapods.org/). Just add this line to your Podfile.

```
pod 'RNFrostedSidebar', '~> 0.1.0'
```

Or if you want to install manually, drag and drop the <code>RNFrostedSidebar</code> .h and .m files into your project. To get this working, you'll need to include the following frameworks in *Link Binary with Libraries*:

- QuartzCore
- Accelerate

**Note:** If you want to compile with Xcode 4.*

## Usage ##



## Customization



## Credits

Sample icons provided by [Pixeden](http://www.pixeden.com/media-icons/tab-bar-icons-ios-7-vol2).

The blur algorithm comes from WWDC 2013's session 208, "What's New in iOS User Interface Design".

## Apps

If you've used this project in a live app, please <a href="mailTo:rnystrom@whoisryannystrom.com">let me know</a>! Nothing makes me happier than seeing someone else take my work and go wild with it.

## Todo

## Contact

* [@nystrorm](https://twitter.com/_ryannystrom) on Twitter
* [@rnystrom](https://github.com/rnystrom) on Github
* <a href="mailTo:rnystrom@whoisryannystrom.com">rnystrom [at] whoisryannystrom [dot] com</a>

## License

See [LICENSE](https://github.com/rnystrom/RNFrostedSidebar/blob/master/LICENSE).
