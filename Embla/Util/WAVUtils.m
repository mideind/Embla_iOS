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

#import "WAVUtils.h"

struct WAVHeader {
    char  riff[4];        // "RIFF"
    long  flength;        // file length in bytes
    char  wave[4];        // "WAVE"
    char  fmt[4];         // "fmt "
    long  chunk_size;     // size of FMT chunk in bytes (usually 16)
    short format_tag;     // 1=PCM, 257=Mu-Law, 258=A-Law, 259=ADPCM
    short num_chans;      // 1=mono, 2=stereo
    long  srate;          // Sampling rate in samples per second
    long  bytes_per_sec;  // bytes per second = srate*bytes_per_samp
    short bytes_per_samp; // 2=16-bit mono, 4=16-bit stereo
    short bits_per_samp;  // Number of bits per sample
    char  data[4];        // "data"
    long  dlength;        // data length in bytes (filelength - 44)
};


@implementation WAVUtils

+ (NSData *)wavDataFromPCM:(NSData *)samples
               numChannels:(NSUInteger)numChannels
                sampleRate:(NSUInteger)sampleRate
             bitsPerSample:(NSUInteger)bitsPerSample {
    
    // Generate header
    struct WAVHeader header = { 0 };
    strncpy(header.riff,"RIFF",4);
    header.flength = [samples length] + 44;
    strncpy(header.wave,"WAVE",4);
    strncpy(header.fmt,"fmt ",4);
    header.chunk_size = 16;
    header.format_tag = 1; // PCM
    header.num_chans =  numChannels;
    header.srate = sampleRate;
    header.bytes_per_sec = sampleRate * (bitsPerSample / 8);
    header.bytes_per_samp = bitsPerSample / 8;
    header.bits_per_samp = bitsPerSample;
    strncpy(header.data,"data",4);
    header.dlength = [samples length];
    
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:&header length:44];
    [data appendData:samples];
    
    return data;
}

@end
