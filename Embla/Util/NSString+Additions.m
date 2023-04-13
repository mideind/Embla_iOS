/*
 * This file is part of the Embla iOS app
 * Copyright (c) 2019-2023 Miðeind ehf.
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

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (BOOL)isPunctuationTerminated {
    return [self hasSuffix:@"."] ||
           [self hasSuffix:@"?"] ||
           [self hasSuffix:@"!"] ||
           [self hasSuffix:@".\""] ||
           [self hasSuffix:@".“"];
}

- (NSString *)sentenceCapitalizedString {
    if ([self length] < 1) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@%@",
            [[self substringToIndex:1] capitalizedString],
            [self substringFromIndex:1]];
}

- (NSString *)periodTerminatedString {
    if (![self isPunctuationTerminated]) {
        return [self stringByAppendingString:@"."];
    }
    return [self copy];
}

- (NSString *)questionMarkTerminatedString {
    if (![self isPunctuationTerminated]) {
        return [self stringByAppendingString:@"?"];
    }
    return [self copy];
}

- (NSString *)icelandic_asciify {
    //Convert Icelandic characters to their ASCII equivalent
    // and then remove all non-ASCII characters.

    NSDictionary *ICECHARS_TO_ASCII = @{
        @"ð": @"d",
        @"Ð": @"D",
        @"á": @"a",
        @"Á": @"A",
        @"ú": @"u",
        @"Ú": @"U",
        @"í": @"i",
        @"Í": @"I",
        @"é": @"e",
        @"É": @"E",
        @"þ": @"th",
        @"Þ": @"TH",
        @"ó": @"o",
        @"Ó": @"O",
        @"ý": @"y",
        @"Ý": @"Y",
        @"ö": @"o",
        @"Ö": @"O",
        @"æ": @"ae",
        @"Æ": @"AE",
    };
    
    NSString *s = [self copy];
    for (NSString *key in ICECHARS_TO_ASCII) {
        s = [s stringByReplacingOccurrencesOfString:key
                                         withString:ICECHARS_TO_ASCII[key]];
    }
    
    NSData *d = [s dataUsingEncoding:NSASCIIStringEncoding
                allowLossyConversion:YES];
    
    return [[NSString alloc] initWithData:d
                                 encoding:NSASCIIStringEncoding];
}

@end
