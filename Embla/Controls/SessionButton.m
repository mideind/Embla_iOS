/*
* This file is part of the Embla iOS app
* Copyright (c) 2019 Miðeind ehf.
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, version 3.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#import "SessionButton.h"
#import "UIColor+Hex.h"
#import "YYImage.h"
#import "AudioWaveformView.h"

#define EXPANSION_DURATION  0.15
#define EXPANSION_SCALE     1.4

@interface SessionButton() {
    CALayer *firstCircleLayer;
    CALayer *secondCircleLayer;
    CALayer *thirdCircleLayer;
    CALayer *imageLayer;
    
    YYAnimatedImageView *animationView;
    
    AudioWaveformView *waveformView;
    NSTimer *waveformTimer;
}
@end

@implementation SessionButton

-  (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
    
    if (self) {
        [self addTarget:self action:@selector(didTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(didTouchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(didTouchUp) forControlEvents:UIControlEventTouchUpOutside];
        [self drawButton];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self addTarget:self action:@selector(didTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(didTouchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(didTouchUp) forControlEvents:UIControlEventTouchUpOutside];
        [self drawButton];
    }
    
    return self;
}

#pragma mark - Events

- (void)didTouchDown {
    // Nothing here for now
}

- (void)didTouchUp {
    // Nothing here for now
}

#pragma mark - Draw

- (void)drawButton {
    self.backgroundColor = [UIColor clearColor];

    UIColor *firstColor = [UIColor colorFromHexString:@"#F9F0F0"]; // outermost circle
    UIColor *secondColor = [UIColor colorFromHexString:@"#F9E2E1"];
    UIColor *thirdColor = [UIColor colorFromHexString:@"#F9DCDB"]; // innermost circle
    
    // Get the root layer
    CALayer *layer = self.layer;
    
    if (!firstCircleLayer) {
        
        // First circle
        firstCircleLayer = [CALayer layer];
        firstCircleLayer.backgroundColor = firstColor.CGColor;
        
        CGFloat size = self.frame.size.width;
        firstCircleLayer.bounds = CGRectMake(0, 0, size, size);
        firstCircleLayer.anchorPoint = CGPointMake(0.5, 0.5);
        firstCircleLayer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
        
        firstCircleLayer.cornerRadius = size/2;
        
        [layer insertSublayer:firstCircleLayer atIndex:0];
        
        // Second circle
        secondCircleLayer = [CALayer layer];
        secondCircleLayer.backgroundColor = secondColor.CGColor;
        
        size = self.frame.size.width/1.25;
        secondCircleLayer.bounds = CGRectMake(0, 0, size, size);
        secondCircleLayer.anchorPoint = CGPointMake(0.5, 0.5);
        secondCircleLayer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
        
        secondCircleLayer.cornerRadius = size/2;
        
        [layer insertSublayer:secondCircleLayer atIndex:1];
        
        // Third circle
        thirdCircleLayer = [CALayer layer];
        thirdCircleLayer.backgroundColor = thirdColor.CGColor;
        
        size = self.frame.size.width/1.75;
        thirdCircleLayer.bounds = CGRectMake(0, 0, size, size);
        thirdCircleLayer.anchorPoint = CGPointMake(0.5, 0.5);
        thirdCircleLayer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
        
        thirdCircleLayer.cornerRadius = size/2;
        
        [layer insertSublayer:thirdCircleLayer atIndex:2];
        
        // Image
        imageLayer = [CALayer layer];
        imageLayer.backgroundColor = [UIColor clearColor].CGColor;
        size = self.frame.size.width/2.5f;
        imageLayer.bounds = CGRectMake(0, 0, size, size);
        imageLayer.anchorPoint = CGPointMake(0.5, 0.5);
        imageLayer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
        imageLayer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"EmblaLogo"].CGImage);
        
        [layer insertSublayer:imageLayer atIndex:3];
    }
}

- (void)layoutSubviews {
    for (CALayer *layer in @[firstCircleLayer, secondCircleLayer, thirdCircleLayer, imageLayer]) {
        layer.anchorPoint = CGPointMake(0.5, 0.5);
        layer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
    }
    [super layoutSubviews];
}

#pragma mark - Animate size

- (void)expand {
    [UIView animateWithDuration:EXPANSION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        self.transform = CGAffineTransformMakeScale(EXPANSION_SCALE, EXPANSION_SCALE);
        CGPoint c = self.center;
        c.y -= 30;
        self.center = c;
        imageLayer.opacity = 0.0f;
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

- (void)contract {
    [UIView animateWithDuration:EXPANSION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        self.transform = CGAffineTransformIdentity;
        CGPoint c = self.center;
        c.y += 30;
        self.center = c;
        imageLayer.opacity = 1.0f;
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

#pragma mark - Logo animation

- (void)startAnimating {
    
    if (!animationView) {
        UIImage *image = [YYImage imageNamed:@"animation.apng"];
        animationView = [[YYAnimatedImageView alloc] initWithImage:image];
    }
    [self addSubview:animationView];
    
    // Animation should have same frame as the logo image layer.
    animationView.bounds = imageLayer.bounds;
    animationView.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
}

- (void)stopAnimating {
    [animationView stopAnimating];
    animationView.currentAnimatedImageIndex = 99;
    [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        animationView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        animationView.currentAnimatedImageIndex = 0;
        [animationView removeFromSuperview];
        animationView.alpha = 1.0f;
    }];
}

#pragma mark - Waveform

- (void)startWaveform {

    // Create and position waveform view
    if (!waveformView) {
        waveformView = [[AudioWaveformView alloc] initWithBars:15 frame:thirdCircleLayer.bounds];
    }
    waveformView.alpha = 0.0f;
    [waveformView reset];
    [self addSubview:waveformView];
    waveformView.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
    
    // Set off update timer for waveform
    [waveformTimer invalidate];
    waveformTimer = nil;
    waveformTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 20 fps
                                                     target:self
                                                   selector:@selector(waveformTicker)
                                                   userInfo:nil
                                                    repeats:YES];
    
    [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        waveformView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

- (void)stopWaveform {
    [waveformView removeFromSuperview];
        
    // Kill timer
    [waveformTimer invalidate];
    waveformTimer = nil;
}

- (void)waveformTicker {
    CGFloat level = [self.audioLevelSource audioLevel];
    [waveformView addSampleLevel:level];
}

@end
