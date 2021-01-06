/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2021 Miðeind ehf.
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
    Singleton wrapper class around OpenEars' Pocketsphinx local speech recognition
    used for hotword activation ("Hæ Embla"/"Hey Embla"). Currently uses an English
    language acoustic model with custom phonemes. Going forward, this should
    probably be replaced with a robust local neural network trained on a large set
    of activation phrase recordings. Reliability is currently much poorer than Siri's.
*/

#import "Common.h"
#import "HotwordDetector.h"
#import "Embla-Swift.h"

@interface HotwordDetector()

@property (nonatomic) PorcupineManager *pm;
@property (nonatomic, copy) NSString *langModelPath;
@property (nonatomic, copy) NSString *genDictPath;

@end

@implementation HotwordDetector

+ (instancetype)sharedInstance {
    static HotwordDetector *instance = nil;
    if (!instance) {
        instance = [self new];
    }
    return instance;
}

- (BOOL)startListening {
    NSError *err;
    self.pm = [[PorcupineManager alloc] initWithModelPath:@"" keywordPath:@"" sensitivity:0.0 error:&err onDetection:^(int32_t ix) {
        [self.delegate didHearHotword:@""];
    }];
    //[self.pm start];
    return TRUE;
}

- (void)stopListening {
    [self.pm stop];
}


@end
