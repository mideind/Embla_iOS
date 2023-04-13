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

#import "WAVUtils.h"

struct WAVHeader {
    char    riff[4];        // "RIFF"
    int     flength;        // File length in bytes minus size of first two struct members (8)
    char    wave[4];        // "WAVE"
    char    fmt[4];         // "fmt "
    int     chunk_size;     // Size of FMT chunk in bytes (usually 16)
    short   format_tag;     // 1=PCM, 257=Mu-Law, 258=A-Law, 259=ADPCM
    short   num_chans;      // 1=mono, 2=stereo
    int     srate;          // Sampling rate in samples per second
    int     bytes_per_sec;  // Bytes per second = srate*bytes_per_samp
    short   bytes_per_samp; // 2=16-bit mono, 4=16-bit stereo, etc.
    short   bits_per_samp;  // Number of bits per sample
    char    data[4];        // "data"
    int     dlength;        // Data length in bytes (filelength - 44 byte WAV header)
};


@implementation WAVUtils

+ (NSData *)wavDataFromPCM:(NSData *)samples
               numChannels:(NSUInteger)numChannels
                sampleRate:(NSUInteger)sampleRate
             bitsPerSample:(NSUInteger)bitsPerSample {
    
    short bytesPerSample = bitsPerSample / 8;
    
    // Generate header
    struct WAVHeader header = { 0 };
    strncpy(header.riff, "RIFF", 4);
    header.flength = (int)([samples length] + 44 - 8);
    strncpy(header.wave, "WAVE", 4);
    strncpy(header.fmt, "fmt ", 4);
    header.chunk_size = 16;
    header.format_tag = 1; // PCM
    header.num_chans =  numChannels;
    header.srate = (int)sampleRate;
    header.bytes_per_sec = (int)(sampleRate * bytesPerSample * numChannels);
    header.bytes_per_samp = bytesPerSample;
    header.bits_per_samp = bitsPerSample;
    strncpy(header.data, "data", 4);
    header.dlength = (int)[samples length];
    
    // Create new data object with header + samples
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:&header length:44];
    [data appendData:samples];
    
    return data;
}

@end
