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
#import "SnowboyDetector.h"
#import "snowboy-detect.h"

@interface SnowboyDetector()
{
    snowboy::SnowboyDetect* _snowboyDetect;
    int detection_countdown;
}
@property BOOL inited;

@end

@implementation SnowboyDetector

+ (instancetype)sharedInstance {
    static SnowboyDetector *instance = nil;
    if (!instance) {
        instance = [self new];
    }
    return instance;
}

- (BOOL)startListening {
    // TODO: Maybe re-initialise every time listening is resumed?
//    if (!self.inited) {
        _snowboyDetect = NULL;
        _snowboyDetect = new snowboy::SnowboyDetect(std::string([[[NSBundle mainBundle]pathForResource:@"common" ofType:@"res"] UTF8String]),
                                                    std::string([[[NSBundle mainBundle]pathForResource:@"embla" ofType:@"umdl"] UTF8String]));
        _snowboyDetect->SetSensitivity("0.5");
        _snowboyDetect->SetAudioGain(1.0);
        _snowboyDetect->ApplyFrontend(false);
        
        [[AudioRecordingService sharedInstance] prepare];
        
        // Start listening
        self.inited = TRUE;
        [self _startListening];
//    }
//    else {
//        // Resume
//    }
    
    self.isListening = TRUE;
    
    return TRUE;
}

- (void)_startListening {
    [[AudioRecordingService sharedInstance] setDelegate:self];
    [[AudioRecordingService sharedInstance] start];
}

- (void)stopListening {
    [[AudioRecordingService sharedInstance] stop];
    self.isListening = FALSE;
}

- (void)processSampleData:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(),^{
        const int16_t *bytes = (int16_t *)[data bytes];
        const int len = [data length]/2;
        int result = _snowboyDetect->RunDetection((const int16_t *)bytes, len);
        if (result == 1) {
            DLog(@"HOTWORD DETECTED");
            detection_countdown = 30;
            if (self.delegate) {
                [self.delegate didHearHotword:@"hæ embla"];
            }
        } else {
            if (detection_countdown == 0){
//                DLog(@"No Hotword Detected");
            } else {
                detection_countdown--;
            }
        }
    });
}

@end
