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

@implementation SessionButton

-  (id)initWithFrame:(CGRect)aRect {
    self = [super initWithFrame:aRect];
    
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
 
}


- (void)didTouchUp {
}

#pragma mark - Draw

- (void)drawButton {

}

@end
