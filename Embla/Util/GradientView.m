//
//  GradientView.m
//  Embla
//
//  Created by Sveinbjorn Thordarson on 07/11/2019.
//  Copyright © 2019 Google. All rights reserved.
//

#import "GradientView.h"
#import "UIColor+Hex.h"

@implementation GradientView

-  (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];

    if (self) {
        [self addGradientLayer];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self addGradientLayer];
    }
    
    return self;
}

- (void)addGradientLayer {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    
    gradient.frame = self.bounds;
    gradient.colors = @[(id)[UIColor colorFromHexString:@"#fafafa"].CGColor,
                        (id)[UIColor colorFromHexString:@"#f9f9f9"].CGColor];
    
    [self.layer insertSublayer:gradient atIndex:0];
}

@end
