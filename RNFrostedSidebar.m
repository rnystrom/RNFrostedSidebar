//
//  RNFrostedMenu.m
//  RNFrostedMenu
//
//  Created by Ryan Nystrom on 8/13/13.
//  Copyright (c) 2013 Ryan Nystrom. All rights reserved.
//

#define __IPHONE_OS_VERSION_SOFT_MAX_REQUIRED __IPHONE_7_0

#import "RNFrostedSidebar.h"
#import <QuartzCore/QuartzCore.h>

NSString *const RNFrostedLabelFont = @"RNFrostedLabelFont";
NSString *const RNFrostedLabelColor = @"RNFrostedLabelColor";

#pragma mark - Categories

@implementation UIView (rn_Screenshot)

- (UIImage *)rn_screenshot {
    UIGraphicsBeginImageContext(self.bounds.size);
    if([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]){
        if (![self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO]) {
            // do not throw exceiption...
//            [NSException raise:@"" format:@"RNFrostedSidebar: unable to drawViewHierarchyInRect!"];
        }
    } else {
        // Important: The OS X v10.5 implementation of this method does not support the entire Core Animation composition model.
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageData = UIImageJPEGRepresentation(image, 0.75);
    image = [UIImage imageWithData:imageData];
    return image;
}

@end

#import <Accelerate/Accelerate.h>

@implementation UIImage (rn_Blur)

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (unsigned)radius, (unsigned)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (unsigned)radius, (unsigned)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (unsigned)radius, (unsigned)radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end

#pragma mark - Private Classes

@interface RNCalloutItemView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) NSInteger itemIndex;
@property (nonatomic, strong) UIColor *originalBackgroundColor;
@end

@implementation RNCalloutItemView

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = UIColor.clearColor;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (instancetype)init {
    if (self = [super init]) {
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat inset = self.bounds.size.height/2;
    self.imageView.frame = CGRectMake(0, 0, inset, inset);
    self.imageView.center = CGPointMake(inset, inset);
}

- (void)setOriginalBackgroundColor:(UIColor *)originalBackgroundColor {
    _originalBackgroundColor = originalBackgroundColor;
    self.backgroundColor = originalBackgroundColor;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGFloat r, g, b, a;
    CGFloat darkenFactor = 0.3f;
    UIColor *darkerColor;
    if ([self.originalBackgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
        darkerColor = [UIColor colorWithRed:MAX(r - darkenFactor, 0.0) green:MAX(g - darkenFactor, 0.0) blue:MAX(b - darkenFactor, 0.0) alpha:a];
    } else if ([self.originalBackgroundColor getWhite:&r alpha:&a]) {
        darkerColor = [UIColor colorWithWhite:MAX(r - darkenFactor, 0.0) alpha:a];
    } else {
        @throw @"Item color should be RGBA or White/Alpha in order to darken the button color.";
    }
    self.backgroundColor = darkerColor;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.backgroundColor = self.originalBackgroundColor;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor = self.originalBackgroundColor;
}

@end

#pragma mark - Public Classes

@interface RNFrostedSidebar ()

@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, strong) UIImageView *blurView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, copy)   NSArray *images;
@property (nonatomic, copy)   NSArray *labels;
@property (nonatomic, copy)   NSArray *borderColors;
@property (nonatomic, strong) NSMutableIndexSet *selectedIndices;
@property (nonatomic, strong, readonly) UIImage *blurImage;
@end

static RNFrostedSidebar *rn_frostedMenu;

@implementation RNFrostedSidebar
@synthesize blurImage = _blurImage;

+ (instancetype)visibleSidebar {
    return rn_frostedMenu;
}

#pragma mark - Getters

- (NSArray *)views {
    const SEL selector = NSSelectorFromString(@"originalBackgroundColor");
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (UIView *view in self.view.subviews) {
        if ([view.class isSubclassOfClass:UIScrollView.class]) {
            for (UIView *individualView in view.subviews) {
                if ([individualView respondsToSelector:selector]) {
                    [result addObject:individualView];
                }
            }
        }
    }
    return result.copy;
}

- (NSMutableIndexSet *)selectedIndices {
    if (!_selectedIndices) {
        _selectedIndices = [[NSMutableIndexSet alloc] init];
    }
    return _selectedIndices;
}

- (UIScrollView *)contentView {
    if (!_contentView) {
        _contentView = [[UIScrollView alloc] init];
        _contentView.alwaysBounceHorizontal = NO;
        _contentView.alwaysBounceVertical = YES;
        _contentView.bounces = YES;
        _contentView.clipsToBounds = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.showsVerticalScrollIndicator = NO;
    }
    return _contentView;
}

- (NSMutableArray *)itemViews {
    if (!_itemViews) {
        _itemViews = [[NSMutableArray alloc] init];
    }
    return _itemViews;
}

- (NSArray *)labels {
    if (!_labels) {
        _labels = @[];
    }
    return _labels;
}

- (UIColor *)tintColor {
    if (!_tintColor) {
        _tintColor = [UIColor colorWithWhite:0.2 alpha:0.73];
    }
    return _tintColor;
}

- (UIColor *)itemBackgroundColor {
    if (!_itemBackgroundColor) {
        _itemBackgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
    }
    return _itemBackgroundColor;
}

#pragma mark - Constructors

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors labelStrings:(NSArray*)labels
{
    if (self = [super init]) {
        self.isSingleSelect = NO;
        
        self.width = 150;
        self.animationDuration = 0.25f;
        self.itemSize = CGSizeMake(_width/2, _width/2);
        
        self.borderWidth = 2;
        
        NSAssert(labels.count == images.count, @"Label count must match images count. If you don't want a labeled button, use @\"\"  If you want a blank border, use UIColor.clearColor.");
        
        self.selectedIndices = selectedIndices.mutableCopy;
        self.borderColors = colors;
        self.images = images;
        
        NSMutableArray *labelsArray = [[NSMutableArray alloc] init];
        
        [self.images enumerateObjectsUsingBlock:^(UIImage *image, NSUInteger idx, BOOL *stop) {
            RNCalloutItemView *view = [[RNCalloutItemView alloc] init];
            view.itemIndex = idx;
            view.clipsToBounds = YES;
            view.imageView.image = image;

            [self.contentView addSubview:view];

            [self.itemViews addObject:view];
			
			if (labels) {
				UILabel* label = [[UILabel alloc] init];
				label.textColor = UIColor.whiteColor;
				label.font = [UIFont systemFontOfSize:14];
				label.text = labels[idx];
				label.backgroundColor = UIColor.clearColor;
				label.textAlignment = NSTextAlignmentCenter;
                label.numberOfLines = 0;
				[labelsArray addObject:label];
				[self.contentView addSubview:label];
			}
            
            UIColor *borderColor = (self.borderColors && [self.selectedIndices containsIndex:idx])
                ? self.borderColors[idx]
                : UIColor.clearColor;
            view.layer.borderColor = borderColor.CGColor;
        }];
        
        self.labels = labelsArray;
        
        rn_frostedMenu = self;
    }
    return self;
}

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices borderColors:(NSArray *)colors {
	return [self initWithImages:images selectedIndices:selectedIndices borderColors:colors labelStrings:nil];
}

- (instancetype)initWithImages:(NSArray *)images selectedIndices:(NSIndexSet *)selectedIndices {
    return [self initWithImages:images selectedIndices:selectedIndices borderColors:nil];
}

- (instancetype)initWithImages:(NSArray *)images {
    return [self initWithImages:images selectedIndices:nil borderColors:nil];
}

- (instancetype)init {
    NSAssert(NO, @"Unable to create with plain init.");
    return nil;
}

#pragma mark - Setters

- (void)setLabelOptions:(NSDictionary*)options
{
	[self.labels enumerateObjectsUsingBlock:^(UILabel* label, NSUInteger idx, BOOL *stop) {
		[label setFont:options[RNFrostedLabelFont]];
		[label setTextColor:options[RNFrostedLabelColor]];
	}];
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.contentView];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:self.tapGesture];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) blurImageNeedsUpdate {
    if (self.isViewLoaded && self.view.window) {
        self.view.alpha = 0;
        self.blurView.alpha = 0;
        
        self.blurView.frame = self.contentView.frame;
        _blurImage = nil;
        self.blurView.image = self.blurImage;

        [UIView animateWithDuration:1.0 animations:^{
            self.view.alpha = 1;
            self.blurView.alpha = 1;
        }];
        
        //   [self layoutSubviews];
        //   [self blurImageNeedsUpdate];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self blurImageNeedsUpdate];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.view.alpha = 0;
    self.blurView.alpha = 0;
    
    [self layoutSubviews];
}

#pragma mark - Show

- (void)animateSpringWithView:(RNCalloutItemView *)view idx:(NSUInteger)idx initDelay:(CGFloat)initDelay {
#if __IPHONE_OS_VERSION_SOFT_MAX_REQUIRED
    [UIView animateWithDuration:0.5
                          delay:(initDelay + idx*0.1f)
         usingSpringWithDamping:10
          initialSpringVelocity:50
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         view.layer.transform = CATransform3DIdentity;
                         view.alpha = 1;
                     }
                     completion:nil];
#endif
}

- (void)animateFauxBounceWithView:(RNCalloutItemView *)view idx:(NSUInteger)idx initDelay:(CGFloat)initDelay {
    [UIView animateWithDuration:0.2
                          delay:(initDelay + idx*0.1f)
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1);
                         view.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.1 animations:^{
                             view.layer.transform = CATransform3DIdentity;
                         }];
                     }];
}

- (UIImage *) blurImage {
    if (!_blurImage) {
        UIImage *blurImage = [self.parentViewController.view rn_screenshot];
        _blurImage = [blurImage applyBlurWithRadius:5 tintColor:self.tintColor saturationDeltaFactor:1.8 maskImage:nil];
    }
    return _blurImage;
}

- (void)showInViewController:(UIViewController *)controller animated:(BOOL)animated {
    [rn_frostedMenu dismissAnimated:NO completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(sidebar:willShowOnScreenAnimated:)]) {
        [self.delegate sidebar:self willShowOnScreenAnimated:animated];
    }
    
    [self rn_addToParentViewController:controller callingAppearanceMethods:YES];
    self.view.frame = controller.view.bounds;
    
    CGFloat parentWidth = self.view.bounds.size.width;
    
    CGRect contentFrame = self.view.bounds;
    contentFrame.origin.x = (self.showFromRight) ? parentWidth
    : -self.width;
    contentFrame.size.width = self.width;
    self.contentView.frame = contentFrame;
    
    [self layoutItems];
    
    CGRect blurFrame = CGRectMake((_showFromRight) ? self.view.bounds.size.width
                                                   : 0,
                                  0,
                                  0,
                                  self.view.bounds.size.height);
    
    [self.blurView removeFromSuperview];

    // if blurImage is not the right size for the blurFrame, invalid it
    if (self.blurImage.size.height != blurFrame.size.height
     || self.blurImage.size.width != blurFrame.size.width) {
        _blurImage = nil;
    }
    
    self.blurView = [[UIImageView alloc] initWithImage:self.blurImage];
    self.blurView.frame = blurFrame;
    self.blurView.contentMode = (self.showFromRight) ? UIViewContentModeTopRight
                                                     : UIViewContentModeTopLeft;
    self.blurView.clipsToBounds = YES;
    [self.view insertSubview:self.blurView belowSubview:self.contentView];
    
    contentFrame.origin.x = (self.showFromRight) ? parentWidth - self.width
                                                 : 0;
    blurFrame.origin.x = contentFrame.origin.x;
    blurFrame.size.width = self.width;
    
    void (^animations)() = ^{
        self.contentView.frame = contentFrame;
        self.blurView.frame = blurFrame;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        if (finished && [self.delegate respondsToSelector:@selector(sidebar:didShowOnScreenAnimated:)]) {
            [self.delegate sidebar:self didShowOnScreenAnimated:animated];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:0
                            options:kNilOptions
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
    
    CGFloat initDelay = 0.1f;
    SEL sdkSpringSelector = NSSelectorFromString(@"animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:");
    BOOL sdkHasSpringAnimation = [UIView respondsToSelector:sdkSpringSelector];
    
    [self.itemViews enumerateObjectsUsingBlock:^(RNCalloutItemView *view, NSUInteger idx, BOOL *stop) {
        view.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1);
        view.alpha = 0;
        view.originalBackgroundColor = self.itemBackgroundColor;
        view.layer.borderWidth = self.borderWidth;
        
        if (sdkHasSpringAnimation) {
            [self animateSpringWithView:view idx:idx initDelay:initDelay];
        } else {
            [self animateFauxBounceWithView:view idx:idx initDelay:initDelay];
        }
    }];
}


- (void)showAnimated:(BOOL)animated {
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    [self showInViewController:controller animated:animated];
}

- (void)show {
    [self showAnimated:YES];
}

#pragma mark - Dismiss

- (void)dismiss {
    [self dismissAnimated:YES completion:nil];
}

- (void)dismissAnimated:(BOOL)animated {
    [self dismissAnimated:animated completion:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    void (^completionBlock)(BOOL) = ^(BOOL finished){
        [self rn_removeFromParentViewControllerCallingAppearanceMethods:YES];
        
        if ([self.delegate respondsToSelector:@selector(sidebar:didDismissFromScreenAnimated:)]) {
            [self.delegate sidebar:self didDismissFromScreenAnimated:YES];
        }
		if (completion) {
			completion(finished);
		}
    };
    
    if ([self.delegate respondsToSelector:@selector(sidebar:willDismissFromScreenAnimated:)]) {
        [self.delegate sidebar:self willDismissFromScreenAnimated:YES];
    }
    
    if (animated) {
        CGFloat parentWidth = self.view.bounds.size.width;
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.x = (self.showFromRight) ? parentWidth
                                                     : -_width;
        
        CGRect blurFrame = self.blurView.frame;
        blurFrame.origin.x = (self.showFromRight) ? parentWidth
                                                  : 0;
        blurFrame.size.width = 0;
        
        [UIView animateWithDuration:self.animationDuration
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.contentView.frame = contentFrame;
                             self.blurView.frame = blurFrame;
                         }
                         completion:completionBlock];
    }
    else {
        completionBlock(YES);
    }
}

#pragma mark - Gestures

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    if (! CGRectContainsPoint(self.contentView.frame, location)) {
        [self dismissAnimated:YES completion:nil];
    }
    else {
        NSInteger tapIndex = [self indexOfTap:[recognizer locationInView:self.contentView]];
        if (tapIndex != NSNotFound) {
            [self tryTapItemAtIndex:tapIndex];
        }
    }
}

#pragma mark - Private

- (void)tryTapItemAtIndex:(NSUInteger)index {
    BOOL needsTap = YES;
    
    // if isSingleSelect and already selected, dont tap again.
    if (self.isSingleSelect) {
        needsTap &= ! [self.selectedIndices containsIndex:index];
    }

    // if the delegate says we shouldn't tap, it's authoritative.
    if ([self.delegate respondsToSelector:@selector(sidebar:shouldTapItemAtIndex:)]) {
        needsTap &= [self.delegate sidebar:self shouldTapItemAtIndex:index];
    }
    
    if (needsTap) {
        [self didTapItemAtIndex:index];
    }
}

- (void)didTapItemAtIndex:(NSUInteger)index {
    BOOL didEnable = ! [self.selectedIndices containsIndex:index];
    
    if (self.borderColors) {
        UIColor *stroke = self.borderColors[index];
        UIView *view = self.itemViews[index];
        
        if (didEnable) {
            if (_isSingleSelect) {
                [self.selectedIndices removeAllIndexes];
                [self.itemViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    UIView *aView = (UIView *)obj;
                    [[aView layer] setBorderColor:[[UIColor clearColor] CGColor]];
                }];
            }
            view.layer.borderColor = stroke.CGColor;
            
            CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
            borderAnimation.fromValue = (id)[UIColor clearColor].CGColor;
            borderAnimation.toValue = (id)stroke.CGColor;
            borderAnimation.duration = 0.5f;
            [view.layer addAnimation:borderAnimation forKey:nil];
            
            [self.selectedIndices addIndex:index];
        } else {
            if (!_isSingleSelect) {
                view.layer.borderColor = [UIColor clearColor].CGColor;
                [self.selectedIndices removeIndex:index];
            }
        }
        
        CGRect pathFrame = CGRectMake(-CGRectGetMidX(view.bounds), -CGRectGetMidY(view.bounds), view.bounds.size.width, view.bounds.size.height);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:view.layer.cornerRadius];
        
        // accounts for left/right offset and contentOffset of scroll view
        CGPoint shapePosition = [self.view convertPoint:view.center fromView:self.contentView];
        
        CAShapeLayer *circleShape = [CAShapeLayer layer];
        circleShape.path = path.CGPath;
        circleShape.position = shapePosition;
        circleShape.fillColor = [UIColor clearColor].CGColor;
        circleShape.opacity = 0;
        circleShape.strokeColor = stroke.CGColor;
        circleShape.lineWidth = self.borderWidth;
        
        [self.view.layer addSublayer:circleShape];
        
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
        
        CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        alphaAnimation.fromValue = @1;
        alphaAnimation.toValue = @0;
        
        CAAnimationGroup *animation = [CAAnimationGroup animation];
        animation.animations = @[scaleAnimation, alphaAnimation];
        animation.duration = 0.5f;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [circleShape addAnimation:animation forKey:nil];
    }
    
    if ([self.delegate respondsToSelector:@selector(sidebar:didTapItemAtIndex:)]) {
        [self.delegate sidebar:self didTapItemAtIndex:index];
    }
    if ([self.delegate respondsToSelector:@selector(sidebar:didEnable:itemAtIndex:)]) {
        [self.delegate sidebar:self didEnable:didEnable itemAtIndex:index];
    }
}

- (void)layoutSubviews {
    CGFloat x = (self.showFromRight) ? self.parentViewController.view.bounds.size.width - self.width
                                     : 0;
    self.contentView.frame = CGRectMake(x, 0, self.width, self.parentViewController.view.bounds.size.height);
    self.blurView.frame = self.contentView.frame;
    
    [self layoutItems];
}

- (void)layoutItems {
    CGFloat leftPadding = (self.width - self.itemSize.width)/2;
    CGFloat __block topPadding = leftPadding;
    
    NSMutableArray *labelHeights = [[NSMutableArray alloc] init];
    topPadding = leftPadding;
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        
        // calculate label height
        CGSize maximumLabelSize = CGSizeMake(self.width, FLT_MAX);
        
        NSDictionary *attributes = @{NSFontAttributeName: label.font};
        CGRect rect = [label.text boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
        
        CGSize expectedLabelSize = rect.size;

        [labelHeights addObject:[NSNumber numberWithFloat:expectedLabelSize.height]];

        if (idx > 0) {
            topPadding += [[labelHeights objectAtIndex:idx - 1] floatValue];
            topPadding += leftPadding;
        }
        
        topPadding += self.itemSize.height;

        CGRect frame = CGRectMake(0, topPadding, self.width, expectedLabelSize.height);
        label.frame = frame;
    }];
    
    topPadding = leftPadding;
    [self.itemViews enumerateObjectsUsingBlock:^(RNCalloutItemView *view, NSUInteger idx, BOOL *stop) {
        if (idx > 0) {
            topPadding += [[labelHeights objectAtIndex:idx - 1] floatValue];
            topPadding += self.itemSize.height;
            topPadding += leftPadding;
        }
     
        CGRect frame = CGRectMake(leftPadding, topPadding, self.itemSize.width, self.itemSize.height);
        view.frame = frame;
        view.layer.cornerRadius = frame.size.width/2.f;
    }];
    
    // add height of last item to topPadding
    topPadding += [[labelHeights objectAtIndex:[self.itemViews count] - 1] floatValue];
    topPadding += self.itemSize.height;
    
    self.contentView.contentSize = CGSizeMake(0, topPadding);
}

- (NSInteger)indexOfTap:(CGPoint)location {
    __block NSUInteger index = NSNotFound;
    
    [self.itemViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (CGRectContainsPoint(view.frame, location)) {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (void)rn_addToParentViewController:(UIViewController *)parentViewController callingAppearanceMethods:(BOOL)callAppearanceMethods {
    if (self.parentViewController) {
        [self rn_removeFromParentViewControllerCallingAppearanceMethods:callAppearanceMethods];
    }
    
    if (callAppearanceMethods) {
        [self beginAppearanceTransition:YES animated:NO];
    }
    [parentViewController addChildViewController:self];
    [parentViewController.view addSubview:self.view];
    [self didMoveToParentViewController:self];
    if (callAppearanceMethods) {
        [self endAppearanceTransition];
    }
}

- (void)rn_removeFromParentViewControllerCallingAppearanceMethods:(BOOL)callAppearanceMethods {
    if (callAppearanceMethods) {
        [self beginAppearanceTransition:NO animated:NO];
    }
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    if (callAppearanceMethods) {
        [self endAppearanceTransition];
    }
}

@end
