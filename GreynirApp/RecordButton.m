//
//  RecordButton.m
//  Greynir
//
//  Created by Sveinbjorn Thordarson on 06/06/2019.
//  Copyright © 2019 Google. All rights reserved.
//

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
