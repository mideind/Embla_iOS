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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SessionButtonState) {
  ButtonStateNormal,
  ButtonStateAudio,
  ButtonStateThinking,
};

@protocol AudioLevelDataSource <NSObject>

- (CGFloat)audioVisualizerLevel;

@end

@interface SessionButton : UIButton

@property (weak) id<AudioLevelDataSource> audioLevelDataSource;

- (void)expand;
- (void)contract;

- (void)startAnimating;
- (void)stopAnimating;

- (void)startVisualizer;
- (void)stopVisualizer;

@end
