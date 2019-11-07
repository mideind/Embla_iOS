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

// Query API
#define DEFAULT_QUERY_SERVER        @"https://greynir.is"
#define QUERY_API_PATH              @"/query.api/v1"
#define CLEAR_QHISTORY_API_PATH     @"/query_history.api/v1"

#define REACHABILITY_HOSTNAME       @"greynir.is"

#define ABOUT_URL                   @"https://embla.is/about.html"
#define PRIVACY_URL                 @"https://embla.is/privacy.html"
#define INSTRUCTIONS_URL            @"https://embla.is/instructions.html"

#define REC_SAMPLE_RATE             16000.0f

// Custom debug logging
#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#else
    #define DLog(...)
#endif

// Use macro to abbreviate standard user defaults and
// combat the excessive verbosity of the Cocoa APIs
#define DEFAULTS    [NSUserDefaults standardUserDefaults]
