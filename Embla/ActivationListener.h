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
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>

@protocol ActivationListenerDelegate <NSObject>

- (void)didHearActivationPhrase:(NSString *)phrase;

@end

@interface ActivationListener : NSObject <OEEventsObserverDelegate>

@property (weak) id <ActivationListenerDelegate>delegate;
@property BOOL isListening;

+ (instancetype)sharedInstance;
- (BOOL)startListening;
- (void)stopListening;

@end
