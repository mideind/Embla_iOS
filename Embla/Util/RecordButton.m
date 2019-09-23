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

#import "RecordButton.h"

@implementation RecordButton

- (void)drawRect:(CGRect)rect {
    CGColorRef color = [[UIColor blueColor] CGColor];
    CGColorRef bgColor = [[UIColor whiteColor] CGColor];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddEllipseInRect(ctx, rect);
    CGContextSetFillColorWithColor(ctx, color);
    CGContextFillPath(ctx);
    
    NSLog(@"%@", NSStringFromCGRect(rect));
    
    const UIEdgeInsets insets = UIEdgeInsetsMake(20, 20, 20, 20);
    CGRect innerRect = UIEdgeInsetsInsetRect(rect, insets);
    
    NSLog(@"%@", NSStringFromCGRect(innerRect));
    
    
    CGContextAddEllipseInRect(ctx, innerRect);
    CGContextSetFillColorWithColor(ctx, bgColor);
    CGContextFillPath(ctx);
}

@end
