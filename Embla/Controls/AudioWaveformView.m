/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019 Miðeind ehf.
 * Adapted from Apache 2-licensed code Copyright 2016 Google Inc.
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

/*
    Draw the audio waveform bars shown in Embla's session button.
*/

#import "AudioWaveformView.h"

#define DEFAULT_SPACING     3.5f

@interface AudioWaveformView()
{
    NSMutableArray *waveformArray;
}
@end

@implementation AudioWaveformView

- (instancetype)initWithBars:(NSInteger)barCount frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        self.numBars = barCount;
        self.spacing = DEFAULT_SPACING;
        waveformArray = [NSMutableArray new];
        [self resetWithLevel:0.1];
    }
    return self;
}

- (void)addSampleLevel:(CGFloat)level {
    [waveformArray addObject:@(level)];
    while ([waveformArray count] > self.numBars && [waveformArray count]) {
        [waveformArray removeObjectAtIndex:0];
    }
    // Tell display server this view needs to be redrawn.
    [self setNeedsDisplay];
}

// Populate waveform array with a given value
- (void)resetWithLevel:(CGFloat)level {
    [waveformArray removeAllObjects];
    while ([waveformArray count] < self.numBars) {
        [waveformArray addObject:@(level)];
    }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGFloat margin = self.spacing;
    CGFloat totalMarginWidth = self.numBars * margin;

    CGFloat barWidth = (self.bounds.size.width - totalMarginWidth) / self.numBars;
    CGFloat barHeight = self.bounds.size.height / 2;
    CGFloat centerY = self.bounds.size.height / 2;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(c, YES);
    CGContextSetShouldAntialias(c, YES);
    
    // Draw bar for each value in waveform array
    for (int i = 0; i < [waveformArray count]; i++) {
        CGFloat level = [waveformArray[i] floatValue];
        
        // Draw top bar
        CGRect topRect = {  i * (barWidth + margin),
                            barHeight - (level * barHeight),
                            barWidth,
                            level * barHeight };
        CGContextSetRGBFillColor(c, 232/255.f, 57/255.f, 57/255.f, 1.0);
        CGContextSetRGBStrokeColor(c, 232/255.f, 57/255.f, 57/255.f, 1.0);
        CGContextFillRect(c, topRect);
        
        // Draw bottom bar
        CGRect bottomRect = {   i * (barWidth + margin),
                                centerY,
                                barWidth,
                                level * barHeight };
        CGContextSetRGBFillColor(c, 242/255.f, 145/255.f, 143/255.f, 1.0);
        CGContextSetRGBStrokeColor(c, 242/255.f, 145/255.f, 143/255.f, 1.0);
        CGContextFillRect(c, bottomRect);
    }
}

#pragma mark - Don't intercept touch events

- (id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    } else {
        return hitView;
    }
}

@end
