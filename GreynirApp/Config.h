/*
 * This file is part of the Greynir iOS app
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

// Util
#define FILE_CONTENTS(X)\
[[NSString stringWithContentsOfFile:(X) encoding:NSUTF8StringEncoding error:nil] \
stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]

#define BUNDLE_PATH(X)\
[[NSBundle mainBundle] pathForResource:(X) ofType:nil]

// AWS Polly
#define AWS_COGNITO_REGION          AWSRegionUSWest2
#define AWS_COGNITO_IDENTITY_POOL   FILE_CONTENTS(BUNDLE_PATH(@"AWSPoolID.key"))

// Google Speech API
#define GOOGLE_SPEECH_API_KEY       FILE_CONTENTS(BUNDLE_PATH(@"GoogleAPI.key"))

// Query API
//#define GREYNIR_API_ENDPOINT        @"https://localhost:5000"
#define DEFAULT_QUERY_SERVER        @"https://greynir.is"
#define QUERY_API_PATH              @"/query.api/v1"
#define QUERY_API_ENDPOINT          [NSString stringWithFormat:@"%@/%@", \
                                    [[NSUserDefaults standardUserDefaults] stringForKey:@"QueryServer"], \
                                    QUERY_API_PATH]


// Custom debug logging
#ifdef DEBUG
    #define DLog(...) NSLog(__VA_ARGS__)
#else
    #define DLog(...)
#endif

