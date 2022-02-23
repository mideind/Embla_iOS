/*
* This file is part of the Embla iOS app
* Copyright (c) 2019-2022 Miðeind ehf.
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

#import <UIKit/UIKit.h>

@interface AudioWaveformView : UIView

@property NSInteger numBars;
@property CGFloat spacing;

- (instancetype)initWithBars:(NSInteger)barCount frame:(CGRect)frame;
- (void)addSampleLevel:(CGFloat)level;
- (void)resetWithSampleLevel:(CGFloat)level;
- (void)resetWithSampleMinLevel:(CGFloat)minLevel maxLevel:(CGFloat)maxLevel;
- (void)reset;

@end
