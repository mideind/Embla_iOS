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
#import "AudioVisualizerView.h"
#import "VisView.h"

#define EXPANSION_DURATION  0.2

@interface SessionButton() {
    CALayer *firstCircleLayer;
    CALayer *secondCircleLayer;
    CALayer *thirdCircleLayer;
    CALayer *imageLayer;
    
    CGRect defaultRect;
    CGPoint centerPoint;
    
    UIImageView *animationView;
    AudioVisualizerView *audioView;
    NSTimer *visualizerTimer;
    VisView *visView;
    
    BOOL expanded;
}
@end

@implementation SessionButton

-  (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
    
    if (self) {
        defaultRect = rect;
        centerPoint = self.center;
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
    
}

- (void)didTouchUp {
//    if (expanded) {
//        [self contract];
//    } else {
//        [self expand];
//    }
}

#pragma mark - Draw

- (void)drawRect:(CGRect)rect {
    
}

- (void)drawButton {
    self.backgroundColor = [UIColor clearColor];
    
    UIColor *firstColor = [UIColor colorFromHexString:@"#f5eaea"];
    UIColor *secondColor = [UIColor colorFromHexString:@"#f8dedd"];
    UIColor *thirdColor = [UIColor colorFromHexString:@"#f8d7d6"];
    
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

- (void)expand {
    [UIView animateWithDuration:EXPANSION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        self.transform = CGAffineTransformMakeScale(1.4, 1.4);
        expanded = YES;
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

- (void)contract {
    [UIView animateWithDuration:EXPANSION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut  animations:^{
        self.transform = CGAffineTransformIdentity;
        expanded = NO;
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

- (void)startAnimating {
    imageLayer.hidden = YES;
    if (!animationView) {
        // Load PNG frames
        NSMutableArray *framePaths = [NSMutableArray new];
        for (int i = 0; i < 100; i++) {
            NSString *s = [NSString stringWithFormat:@"EMBLA_256px_%05d", i];
            s = [[NSBundle mainBundle] pathForResource:s ofType:@"png"];
            [framePaths addObject:s];
        }
        // Create animated image and put it in an image view
        UIImage *image = [[YYFrameImage alloc] initWithImagePaths:framePaths
                                                 oneFrameDuration:0.04166 // 24 fps
                                                        loopCount:0];
        animationView = [[YYAnimatedImageView alloc] initWithImage:image];
        [self addSubview:animationView];
        
        // Center in button
        CGRect r = animationView.bounds;
        r.size.width = 100;
        r.size.height = 100;
        animationView.bounds = r;
        animationView.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};;
    }
    animationView.hidden = NO;
}

- (void)stopAnimating {
    [animationView removeFromSuperview];
    animationView = nil;
    imageLayer.hidden = NO;
}

- (void)startVisualizer {
    
    visView = [[VisView alloc] initWithBars:17 frame:thirdCircleLayer.bounds color:nil];
    [self addSubview:visView];
    visView.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
    imageLayer.hidden = YES;
        
    [visualizerTimer invalidate];
    visualizerTimer = nil;
    visualizerTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(visualizerTimer:) userInfo:nil repeats:YES];
}

- (void)stopVisualizer {
    [visView removeFromSuperview];
    visView = nil;
    imageLayer.hidden = NO;
    
    [visualizerTimer invalidate];
    visualizerTimer = nil;

    return;
    [audioView stopAudioVisualizer];
    [audioView removeFromSuperview];
    audioView = nil;
    
    imageLayer.hidden = NO;
}

- (void)visualizerTimer:(CADisplayLink *)timer {
    
//    const double ALPHA = 1.05;
//
//    double averagePowerForChannel = pow(10, (0.05 * [_audioPlayer averagePowerForChannel:0]));
//    lowPassReslts = ALPHA * averagePowerForChannel + (1.0 - ALPHA) * lowPassReslts;
//
//    double averagePowerForChannel1 = pow(10, (0.05 * [_audioPlayer averagePowerForChannel:1]));
//    lowPassReslts1 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts1;
    
    CGFloat f = [self.audioLevelDataSource audioVisualizerLevel];
    [visView addSampleLevel:f];
    NSLog(@"%.2f", f);
//    [audioView animateAudioVisualizerWithChannel0Level:f andChannel1Level:f];
}

@end
