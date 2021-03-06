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
#import "PocketsphinxDetector.h"

// Valid activation phrases to listen for
#define HOTWORD_PHRASES @[\
@"hi embla", \
@"hiembla", \
@"hey embla", \
@"heyembla", \
@"heymbla", \
@"hoy embla", \
@"hoyembla", \
@"cile embla", \
@"cilembla" \
@"hi embla hi" \
@"hi embla hi embla" \
]

// 0 is certainty.
#define MIN_HYPOTHESIS_SCORE    -190000

// This is how long Pocketsphinx should wait after speech ends to
// attempt to recognize speech. The default is 0.7 seconds.
#define SILENCE_DELAY           0.6f

// Speech/Silence threshhold setting. If quiet background noises are triggering
// speech recognition, this can be raised to a value from 2-3 to 3.5 for the
// English acoustic model being used. Default is 2.3.
#define VAD_THRESHOLD           3.25f

@interface PocketsphinxDetector()

@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, copy) NSString *langModelPath;
@property (nonatomic, copy) NSString *genDictPath;
@property BOOL inited;
@property (weak) id <HotwordDetectorDelegate>delegate;
@property (readonly) BOOL isListening;

@end

@implementation PocketsphinxDetector

+ (instancetype)sharedInstance {
    static PocketsphinxDetector *instance = nil;
    if (!instance) {
        instance = [self new];
        [[OEPocketsphinxController sharedInstance] requestMicPermission];
        instance.openEarsEventsObserver = [[OEEventsObserver alloc] init];
        instance.openEarsEventsObserver.delegate = instance;
    }
    return instance;
}

- (BOOL)startListening {
    // TODO: Maybe re-initialise every time listening is resumed?
    if (!self.inited) {
        // Set up speech recognition via Pocketsphinx
        DLog(@"Initing Pocketsphinx hotword detector");
        
        // Must be called before setting any OEPocketsphinxController characteristics
        [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
        // Configure it
        [[OEPocketsphinxController sharedInstance] setSecondsOfSilenceToDetect:SILENCE_DELAY]; // Default is 0.7
        [[OEPocketsphinxController sharedInstance] setVadThreshold:VAD_THRESHOLD]; // Default is 2.3
        // Custom buffer size is disabled in order to work with Bluetooth devices and device switching
        [[OEPocketsphinxController sharedInstance] setDisablePreferredBufferSize:YES];
//        [[OEPocketsphinxController sharedInstance] setAudioMode:@"VoiceChat"];
//        [[OEPocketsphinxController sharedInstance] setDisableMixing:YES];
//        [[OEPocketsphinxController sharedInstance] setVerbosePocketSphinx:YES];
        
        // Generate language model
        NSArray *langArray = HOTWORD_PHRASES;
        OELanguageModelGenerator *langModelGenerator = [[OELanguageModelGenerator alloc] init];
        // Uncomment for verbose language model generator debug output.
//        langModelGenerator.verboseLanguageModelGenerator = TRUE;
        NSError *error = [langModelGenerator generateLanguageModelFromArray:langArray
                                                             withFilesNamed:@"OEDynamicLanguageModel"
                                                     forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]];
        if (error) {
            DLog(@"Dynamic language model generator error: %@", [error description]);
            return FALSE;
        }
        
        self.langModelPath = [langModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"OEDynamicLanguageModel"];
        self.genDictPath = [langModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"OEDynamicLanguageModel"];
        
        // Start listening
        self.inited = TRUE;
        [self _startOEListening];
    }
    else {
        [[OEPocketsphinxController sharedInstance] resumeRecognition];
    }
    
    _isListening = TRUE;
    
    return TRUE;
}

- (void)stopListening {
    if ([OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] suspendRecognition];
    }
    _isListening = FALSE;
}

#pragma mark -

- (void)_startOEListening {
    DLog(@"StartOEListening");
    if ([OEPocketsphinxController sharedInstance].isListening == FALSE) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.langModelPath
                                                                        dictionaryAtPath:self.genDictPath
                                                                     acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]
                                                                     languageModelIsJSGF:FALSE];
    }
}

#pragma mark - OpenEars Delegate

-(void)pocketsphinxFailedNoMicPermissions {
    self.inited = FALSE;
}

- (void)micPermissionCheckCompleted:(BOOL)result {
    DLog(@"Mic permission result: %d", result);
}

- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis
                        recognitionScore:(NSString *)score
                             utteranceID:(NSString *)utteranceID {
    DLog(@"\"%@\" (Score: %@)", hypothesis, score);
    
    // If no delegate, we're done here
    if (!self.delegate) {
        return;
    }
    
    // Check if it matches activation phrase
    for (NSString *phrase in HOTWORD_PHRASES) {
        if ([hypothesis isEqualToString:phrase] && [score integerValue] > MIN_HYPOTHESIS_SCORE) {
            [self.delegate didHearHotword:hypothesis];
            return;
        }
    }
}

// An optional delegate method of OEEventsObserver which informs that there
// was an interruption to the audio session (e.g. an incoming phone call).
- (void)audioSessionInterruptionDidBegin {
    DLog(@"OE: AudioSession interruption began.");
    if ([OEPocketsphinxController sharedInstance].isListening) {
        // React by telling Pocketsphinx to stop listening since
        // it will need to restart its loop after an interruption.
        NSError *error = [[OEPocketsphinxController sharedInstance] stopListening];
        if (error) {
            DLog(@"Error while stopping listening in audioSessionInterruptionDidBegin: %@", error);
        }
    }
}

// An optional delegate method of OEEventsObserver which informs
// that the interruption to the audio session ended.
- (void)audioSessionInterruptionDidEnd {
    DLog(@"OE: AudioSession interruption ended.");
    // We're restarting the previously-stopped listening loop.
    [self _startOEListening];
}

// An optional delegate method of OEEventsObserver which informs
// that the audio input became unavailable.
- (void)audioInputDidBecomeUnavailable {
    DLog(@"OE: The audio input has become unavailable");
    if ([OEPocketsphinxController sharedInstance].isListening){
        // React to it by telling Pocketsphinx to stop listening
        // since there is no available input (but only if we are listening).
        NSError *error = [[OEPocketsphinxController sharedInstance] stopListening];
        if (error) {
            DLog(@"Error while stopping listening in audioInputDidBecomeUnavailable: %@", error);
        }
    }
}

// An optional delegate method of OEEventsObserver which informs
// that the unavailable audio input became available again.
- (void)audioInputDidBecomeAvailable {
    DLog(@"OE: The audio input is available");
    [self _startOEListening];
}

// An optional delegate method of OEEventsObserver which informs that there was a
// change to the audio route (e.g. headphones were plugged in or unplugged).
- (void)audioRouteDidChangeToRoute:(NSString *)newRoute {
    DLog(@"OE: Audio route change. The new audio route is %@", newRoute);
    
    // React to it by telling the Pocketsphinx loop to shut down and
    // then start listening again on the new route
    NSError *error = [[OEPocketsphinxController sharedInstance] stopListening];
    if (error) {
        DLog(@"OE: Error while stopping listening in audioRouteDidChangeToRoute: %@", error);
    }
    
    [self _startOEListening];
}

// An optional delegate method of OEEventsObserver which informs that the
// Pocketsphinx recognition loop has entered its actual loop. This might
// be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void)pocketsphinxRecognitionLoopDidStart {
    DLog(@"OE: Pocketsphinx started.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx
// is now listening for speech.
- (void)pocketsphinxDidStartListening {
    DLog(@"OE: Pocketsphinx is now listening.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx
// detected speech and is starting to process it.
- (void)pocketsphinxDidDetectSpeech {
    DLog(@"OE: Pocketsphinx has detected speech.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx
// detected a second of silence, indicating the end of an utterance.
// This was added because developers requested being able to time the recognition
// speed without the speech time. The processing time is the time between
// this method being called and the hypothesis being returned.
- (void)pocketsphinxDidDetectFinishedSpeech {
    DLog(@"OE: Pocketsphinx has detected finished speech, concluding an utterance.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx
// has exited its recognition loop, most likely in response to the OEPocketsphinxController
// being told to stop listening via the stopListening method.
- (void)pocketsphinxDidStopListening {
    DLog(@"OE: Pocketsphinx has stopped listening.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is
// still in its listening loop but it is not going to react to speech until listening
// is resumed.  This can happen as a result of the OEPocketsphinxController being told
// to suspend recognition via the suspendRecognition method.
- (void)pocketsphinxDidSuspendRecognition {
    DLog(@"OE: Pocketsphinx has suspended recognition.");
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is
// still in its listening loop and after recognition having been suspended it is now resuming.
// This can happen as a result of the OEPocketsphinxController being told to resume recognition
// via the resumeRecognition method.
- (void)pocketsphinxDidResumeRecognition {
    DLog(@"OE: Pocketsphinx has resumed recognition.");
}

// An optional delegate method which informs that Pocketsphinx switched over to a new language
// model at the given URL in the course of recognition. This does not imply that it is a valid
// file or that recognition will be successful using the file.
- (void)pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPath andDictionary:(NSString *)newDictionaryPath {
    DLog(@"OE: Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",
          newLanguageModelPath, newDictionaryPath);
}

@end
