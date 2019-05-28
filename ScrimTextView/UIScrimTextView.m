//
//  UIScrimTextView
//  ScrimTextView
//
//  Created by Garg, Shweta on 28/05/19.
//  Copyright © 2019 Garg, Shweta. All rights reserved.
//

#import "UIScrimTextView.h"

@interface UIScrimTextView() <UITextViewDelegate>

typedef NS_ENUM(NSUInteger, TextViewScrollPosition) {
    TextViewScrollPositionTop,
    TextViewScrollPositionMiddle,
    TextViewScrollPositionBottom
};

@property (strong, nonatomic) UITextView* descriptionTextView;
@property (nonatomic) TextViewScrollPosition scrollPosition;

@end

@implementation UIScrimTextView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInitialize];
    }
    return self;
}

- (void)customInitialize {
    _descriptionTextView = [[UITextView alloc] initWithFrame:self.bounds];
    _descriptionTextView.backgroundColor = [UIColor clearColor];
    _descriptionTextView.textColor = [UIColor whiteColor];
    _descriptionTextView.font = [UIFont systemFontOfSize:36.f];
    _descriptionTextView.textAlignment = NSTextAlignmentLeft;
    _descriptionTextView.editable = NO;
    _descriptionTextView.selectable = NO;
    _descriptionTextView.scrollEnabled = YES;

    [self addSubview:_descriptionTextView];
    _descriptionTextView.delegate = self;

    _scrollPosition = TextViewScrollPositionTop;
    [self maskForScrollPosition:_scrollPosition];
}

- (void)layoutSubviews {
    _descriptionTextView.frame = CGRectMake(0, 0,
                                            CGRectGetWidth(self.bounds),
                                            CGRectGetHeight(self.bounds));
    [self scrollToTop];
}

- (void)addConstraint:(NSLayoutConstraint *)constraint {
    [_descriptionTextView.topAnchor constraintEqualToAnchor:self.topAnchor];
    [_descriptionTextView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
    [_descriptionTextView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    [_descriptionTextView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    if (layer == self.layer) {
        [CATransaction setDisableActions:YES];
        self.layer.mask.frame = self.bounds;
        [CATransaction setDisableActions:NO];
    }
}

- (void)scrollToTop {
    [_descriptionTextView setContentOffset:CGPointZero animated:NO];
}

- (void)setText:(NSString*)text {
    _text = text;
    _descriptionTextView.text = text;
    [self scrollToTop];
}

- (void)maskForScrollPosition:(TextViewScrollPosition)scrollPosition {
    // This is a maskLayer, so transparency is inverted from expectations.
    UIColor* scrimTransparent = [UIColor colorWithRed:0.29f green:0.29f blue:0.29f alpha:1.0f];
    UIColor* scrimOpaque = [UIColor colorWithRed:0.29f green:0.29f blue:0.29f alpha:0.0f];

    NSArray* toColors;
    switch (scrollPosition) {
        case TextViewScrollPositionTop:
            // invisible scrim on the top; visible scrim on the bottom
            toColors = @[(id)scrimTransparent.CGColor, (id)scrimTransparent.CGColor, (id)scrimTransparent.CGColor, (id)scrimOpaque.CGColor];
            break;
        case TextViewScrollPositionMiddle:
            // visible scrim on the top; visible scrim on the bottom;
            toColors = @[(id)scrimOpaque.CGColor, (id)scrimTransparent.CGColor, (id)scrimTransparent.CGColor, (id)scrimOpaque.CGColor];
            break;
        case TextViewScrollPositionBottom:
            // visible scrim on the top; invisible scrim on the bottom;
            toColors = @[(id)scrimOpaque.CGColor, (id)scrimTransparent.CGColor, (id)scrimTransparent.CGColor, (id)scrimTransparent.CGColor];
            break;
    }

    CAGradientLayer* maskLayer = self.layer.mask;
    if (!maskLayer) {
        // Don't animate the initial creation!
        maskLayer = [CAGradientLayer layer];

        maskLayer.colors = toColors;
        maskLayer.locations = @[@0.f, @0.15f, @0.85f, @1.f];
        maskLayer.frame = self.bounds;
        self.layer.mask = maskLayer;
        return;
    }

    // Handle changes in the layout of the scrimView.
    maskLayer.frame = self.bounds;

    CABasicAnimation* fadeScrim = [CABasicAnimation animationWithKeyPath:@"colors"];
    if (maskLayer.presentationLayer) {
        // In the middle of an animation already, use that as the starting point.
        fadeScrim.fromValue = maskLayer.presentationLayer.colors;
    } else {
        fadeScrim.fromValue = maskLayer.colors;
    }

    fadeScrim.duration = 0.3f;
    fadeScrim.removedOnCompletion = YES;
    fadeScrim.fillMode = kCAFillModeForwards;
    fadeScrim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeScrim.toValue = toColors;

    [CATransaction begin];
    // Animations don't actually set properties. We need to set it here, or the colors will revert
    // to previous values when the animation is removed.
    // We also do this in a transaction so we can tell CA not to apply this change right now.
    [CATransaction setDisableActions:YES];
    maskLayer.colors = toColors;
    [CATransaction commit];

    [maskLayer addAnimation:fadeScrim forKey:@"fadeScrim"];
 }

//MARK: UITextViewDelegate
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    float scrollViewHeight = scrollView.frame.size.height;
    float contentHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;

    if (scrollOffset <= 0) {
        if (_scrollPosition != TextViewScrollPositionTop) {
            // then we are at top
            _scrollPosition = TextViewScrollPositionTop;
            [self maskForScrollPosition:_scrollPosition];
        }
    } else if (scrollOffset + scrollViewHeight >= contentHeight) {
        if (_scrollPosition != TextViewScrollPositionBottom) {
            // then we are at the end
            _scrollPosition = TextViewScrollPositionBottom;
            [self maskForScrollPosition:_scrollPosition];
        }
    } else {
        if (_scrollPosition != TextViewScrollPositionMiddle) {
            // then we are in middle
            _scrollPosition = TextViewScrollPositionMiddle;
            [self maskForScrollPosition:_scrollPosition];
        }
    }
}

@end
