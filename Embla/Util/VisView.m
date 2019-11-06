//
//  VisView.m
//  Embla
//
//  Created by Sveinbjorn Thordarson on 06/11/2019.
//  Copyright © 2019 Google. All rights reserved.
//

#import "VisView.h"
#import "UIColor+Hex.h"
#import "Common.h"

#define MAX_BAR_COUNT 50

@interface VisView()
{
    NSMutableArray *waveFormArray;
    UIColor *color;
    NSInteger numBars;
    
    NSTimer *timer;
    CGFloat offset;
}
@end

@implementation VisView

- (instancetype)initWithBars:(NSInteger)barCount frame:(CGRect)frame color:(UIColor *)aColor {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        
        numBars = barCount;
        color = aColor;
        waveFormArray = [NSMutableArray new];
        
        // For debugging layout
//        self.layer.borderColor = [UIColor redColor].CGColor;
//        self.layer.borderWidth = 1.0f;
        
//        [self start];
    }
    
    return self;
}

//- (void)start {
//    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(tick) userInfo:nil repeats:YES];
//}
//
//- (void)tick {
//    [self setNeedsDisplay];
//}

- (void)addSampleLevel:(CGFloat)level {
    [waveFormArray addObject:@(level)];
    if ([waveFormArray count] > numBars) {
        [waveFormArray removeObjectAtIndex:0];
    }
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    DLog(@"Drawing");
    CGFloat margin = 3.0f;
    CGFloat totalMarginWidth = numBars * margin;

    CGFloat barWidth = (self.bounds.size.width - totalMarginWidth) / numBars;
    CGFloat barHeight = self.bounds.size.height / 2;
    CGFloat centerY = self.bounds.size.height / 2;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
        
    for (int i = 0; i < [waveFormArray count]; i++) {
        CGFloat level = [waveFormArray[i] floatValue];
        CGFloat val = level;
        
        // Draw top bar
        CGRect topRect = {i * (barWidth + margin), barHeight - (val * barHeight), barWidth, val * barHeight};
//        NSLog(NSStringFromCGRect(topRect));
        CGContextSetRGBFillColor(c, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBStrokeColor(c, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(c, topRect);
        
        // Draw bottom bar
        CGRect bottomRect = {i * (barWidth + margin), centerY, barWidth, val * barHeight};
        CGContextSetRGBFillColor(c, 242/255.f, 145/255.f, 143/255.f, 1.0);
        CGContextSetRGBStrokeColor(c, 242/255.f, 145/255.f, 143/255.f, 1.0);
        CGContextFillRect(c, bottomRect);
    }
}

//242, 145, 143


@end
