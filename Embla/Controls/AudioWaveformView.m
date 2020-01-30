/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2020 Miðeind ehf.
 * Author: Sveinbjorn Thordarson
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

#define AWV_DEFAULT_NUM_BARS        15
#define AWV_DEFAULT_BAR_SPACING     3.5f
#define AWV_DEFAULT_SAMPLE_LEVEL    0.07f // A hard lower limit above 0 looks better

@interface AudioWaveformView()
{
    NSMutableArray *waveformArray;
}
@end

@implementation AudioWaveformView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithBars:AWV_DEFAULT_NUM_BARS frame:frame];
}

- (instancetype)initWithBars:(NSInteger)barCount frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor clearColor];
        self.numBars = barCount;
        self.spacing = AWV_DEFAULT_BAR_SPACING;
        waveformArray = [NSMutableArray new];
        [self reset];
    }
    return self;
}

#pragma mark -

- (void)addSampleLevel:(CGFloat)level {
//    if (level < AWV_DEFAULT_SAMPLE_LEVEL) {
//        level = AWV_DEFAULT_SAMPLE_LEVEL;
//    }
    [waveformArray addObject:@(level)];
    while ([waveformArray count] > self.numBars && [waveformArray count]) {
        [waveformArray removeObjectAtIndex:0];
    }
    // Tell display server this view needs to be redrawn
    [self setNeedsDisplay];
}

// Populate waveform array with a given value
- (void)resetWithSampleLevel:(CGFloat)level {
    [waveformArray removeAllObjects];
    while ([waveformArray count] < self.numBars) {
        [waveformArray addObject:@(level)];
    }
}

// Populate waveform array with default value
- (void)reset {
    [self resetWithSampleLevel:AWV_DEFAULT_SAMPLE_LEVEL];
}

#pragma mark - Drawing

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
        CGRect topRect = {  i * (barWidth + margin) + (margin/2), // x
                            barHeight - (level * barHeight), // y
                            barWidth, // width
                            level * barHeight }; // height
        CGContextSetRGBFillColor(c, 232/255.f, 57/255.f, 57/255.f, 1.0);
        CGContextFillRect(c, topRect);
        CGContextAddArc(c,
                        i * (barWidth + margin) + barWidth/2 + (margin/2), // x
                        barHeight - (level * barHeight), // y
                        barWidth/2, // radius
                        0.0, M_PI*2, YES);
        CGContextFillPath(c);
        
        // Draw bottom bar
        CGRect bottomRect = {   i * (barWidth + margin) + (margin/2), // x
                                centerY, // y
                                barWidth, // width
                                level * barHeight }; // height
        CGContextSetRGBFillColor(c, 242/255.f, 145/255.f, 143/255.f, 1.0);
        CGContextFillRect(c, bottomRect);
        CGContextAddArc(c,
                        i * (barWidth + margin) + barWidth/2 + (margin/2), // x
                        centerY + (level * barHeight), // y
                        barWidth/2, // radius
                        0.0, M_PI*2, YES);
        CGContextFillPath(c);
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
