/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2021 Miðeind ehf.
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

#import "DataURI.h"


#define DATA_URI_PREFIX         @"data:"


@interface DataURI ()
{
    NSString *urlString;
    NSString *mimeType;
    NSData *data;
}
@end


@implementation DataURI

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        if (![self _parse:string]) {
            return nil;
        }
        urlString = string;
    }
    return self;
}

- (BOOL)_parse:(NSString *)string {
    // Parse Data URI format
    // data:[<media type>][;base64],<data>
    
    if (![DataURI isDataURI:string]) {
        return FALSE;
    }
    
    NSUInteger prefixLen = [DATA_URI_PREFIX length];
    NSUInteger splitPos = prefixLen;
    
    const char *str = [string cStringUsingEncoding:NSASCIIStringEncoding];
    
    for (NSUInteger i = prefixLen; i < [string length]; i++) {
        // This is not really correct since the mime type *may* contain a comma,
        // e.g. data:video/webm; codecs=\"vp8, opus\";base64,GkXfowEAAAAAA...
        if (str[i] == ',') {
            splitPos = i;
            break;
        }
    }
    
    const char *p = str + prefixLen;
    NSString *m = [[NSString alloc] initWithBytes:p
                                           length:splitPos - prefixLen
                                         encoding:NSASCIIStringEncoding];
    mimeType = @"";
    if ([m length]) {
        NSArray *a = [m componentsSeparatedByString:@";"];
        mimeType = [[a objectAtIndex:0] copy];
    }
    
    const char *dataptr = str + splitPos + 1;
    NSString *base64str = [[NSString alloc] initWithBytesNoCopy:(void *)dataptr
                                                         length:[string length] - splitPos
                                                       encoding:NSASCIIStringEncoding
                                                   freeWhenDone:NO];
    data = [[NSData alloc] initWithBase64EncodedString:base64str
                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return (data != nil);
}

- (NSData *)data {
    return data;
}

- (NSString *)mimeType {
    return mimeType;
}

+ (BOOL)isDataURI:(NSString *)string {
    return [string hasPrefix:DATA_URI_PREFIX];
}

@end
