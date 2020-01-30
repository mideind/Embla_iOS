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

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (BOOL)isPunctuationTerminated {
    return [self hasSuffix:@"."] || [self hasSuffix:@"?"] || [self hasSuffix:@"!"];
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

@end
