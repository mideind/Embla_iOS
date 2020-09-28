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

#import <Foundation/Foundation.h>


@interface QueryService : NSObject

+ (instancetype)sharedInstance;
- (void)sendQuery:(id)query withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;
- (void)requestSpeechSynthesis:(NSString *)str withCompletionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler;
- (void)clearUserData:(BOOL)allData completionHandler:(id)completionHandler;

@end

