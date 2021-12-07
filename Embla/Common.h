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

// Hotword detection
#define DEFAULT_HOTWORD_DETECTOR        @"Snowboy"

// Query API
#define DEFAULT_QUERY_SERVER            @"https://greynir.is"
#define QUERY_API_PATH                  @"/query.api/v1"
#define CLEAR_QHISTORY_API_PATH         @"/query_history.api/v1"
#define SPEECH_API_PATH                 @"/speech.api/v1"

// Speech-to-text API
#define DEFAULT_SPEECH2TEXT_SERVER      @"speech.googleapis.com:443"
#define NUM_SPEECH2TEXT_ALTERNATIVES    10
#define SPEECH2TEXT_LANGUAGE            @"is-IS"

// Hotword training
#define DEFAULT_HOTWORD_SERVER          @"192.168.1.3:8000"
#define HOTWORD_TRAINING_API_PATH       @"/train/v1"
#define DEFAULT_HOTWORD_MODEL           @"old.pmdl"

// Hostname used to determine if the device is connected to the internet.
#define REACHABILITY_HOSTNAME           @"greynir.is"

// Remote HTML documentation
#define ABOUT_URL                       @"https://embla.is/about.html"
#define PRIVACY_URL                     @"https://embla.is/privacy.html"
#define INSTRUCTIONS_URL                @"https://embla.is/instructions.html"

// Client info
#define CLIENT_NAME                     @"Embla"
#define CLIENT_TYPE                     @"ios"
#define CLIENT_OSNAME                   @"iOS"
#define CLIENT_VERSION                  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
#define CLIENT_BUILD                    [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]

// Sample rate for microphone audio recording
#define REC_SAMPLE_RATE                 16000.0f

// Minimum acceptable speech to text result stability, on a range of 0-1.0,
// used to determine whether an interim STT result is reasonably reliable.
#define MIN_STT_RESULT_STABILITY        0.25f

// Logging in debug mode only
#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#else
    #define DLog(...)
#endif

// Use macro to abbreviate standard user defaults and
// combat the excessive verbosity of the Cocoa APIs.
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
