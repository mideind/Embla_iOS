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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@protocol QuerySessionDelegate <NSObject>

- (void)sessionDidStartRecording;
- (void)sessionDidStopRecording;
- (void)sessionDidReceiveInterimResults:(NSArray<NSString *> *)results;
- (void)sessionDidReceiveTranscripts:(NSArray<NSString *> *)transcripts;
- (void)sessionDidReceiveAnswer:(NSString *)answer toQuestion:(NSString *)question withURL:(NSURL *)url;
- (void)sessionDidRaiseError:(NSError *)err;
- (void)sessionDidTerminate;

@end


@interface QuerySession : NSObject

@property (nonatomic, weak) id<QuerySessionDelegate> delegate;
@property (readonly) CGFloat audioLevel;
@property (readonly) BOOL isRecording;
@property (readonly) BOOL terminated;

- (instancetype)initWithDelegate:(id<QuerySessionDelegate>)del;
- (void)start;
- (void)terminate;

@end
