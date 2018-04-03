//
//  RecordAudio.m
//  JuuJuu
//
//  Created by xiaoguang huang on 11-12-19.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "RecordAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "amrFileCodec.h"

@implementation WeakPtr

@synthesize weakObj = _weakObj;

@end

@interface RecordAudio ()

/**
 录音音量计量表定时器
 */
@property (strong, nonatomic) dispatch_source_t meterTimer;

@end

@implementation RecordAudio


- (void)dealloc {
    [recorder dealloc];
	recorder = nil;
	recordedTmpFile = nil;
    [avPlayer stop];
    [avPlayer release];
    avPlayer = nil;
    [super dealloc];
}

-(id)init {
    self = [super init];
    if (self) {
        //Instanciate an instance of the AVAudioSession object.
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        //Setup the audioSession for playback and record. 
        //We could just use record and then switch it to playback leter, but
        //since we are going to do both lets set it up once.
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
								 sizeof (audioRouteOverride),
								 &audioRouteOverride);
        
        //Activate the session
        [audioSession setActive:YES error: &error];
    }
    return self;
}

- (NSURL *) stopRecord {
    NSURL *url = 
    [[NSURL alloc]initWithString:recorder.url.absoluteString];
    recorder.meteringEnabled = NO;
    [recorder stop];
    [recorder release];
    recorder =nil;
    [self stopMeterTimer];
    return [url autorelease];
}

+(NSTimeInterval) getAudioTime:(NSData *) data {
    NSError * error;
    AVAudioPlayer*play = [[AVAudioPlayer alloc] initWithData:data error:&error];
    NSTimeInterval n = [play duration];
    [play release];
    return n;
}

//0 播放 1 播放完成 2出错
-(void)sendStatus:(int)status {
    
    if ([self.delegate respondsToSelector:@selector(RecordStatus:)]) {
        [self.delegate RecordStatus:status];
    }
    
    if (status!=0) {
        if (avPlayer!=nil) {
            [avPlayer stop];
            [avPlayer release];
            avPlayer = nil;
        }
    }
}

-(void) stopPlay {
    if (avPlayer!=nil) {
        [avPlayer stop];
        [avPlayer release];
        avPlayer = nil;
        [self sendStatus:1];
    }
}

-(NSData *)decodeAmr:(NSData *)data{
    if (!data) {
        return data;
    }

    return DecodeAMRToWAVE(data);
}

-(void) play:(NSData*) data{
	//Setup the AVAudioPlayer to play the file that we just recorded.
    //在播放时，只停止
    if (avPlayer!=nil) {
        [self stopPlay];
        return;
    } 
    NSLog(@"start decode");
    NSData* o = [self decodeAmr:data];
        NSLog(@"end decode");
    avPlayer = [[AVAudioPlayer alloc] initWithData:o error:&error];
    avPlayer.delegate = self;
	[avPlayer prepareToPlay];
    [avPlayer setVolume:1.0];
	if(![avPlayer play]){
        [self sendStatus:1];
    } else {
        [self sendStatus:0];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self sendStatus:1];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    [self sendStatus:2];
}

-(void) startRecord {
    //Begin the recording session.
    //Error handling removed.  Please add to your own code.
    
    //Setup the dictionary object with all the recording settings that this 
    //Recording sessoin will use
    //Its not clear to me which of these are required and which are the bare minimum.
    //This is a good resource: http://www.totodotnet.net/tag/avaudiorecorder/
    //		NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    //		[recordSetting setValue :[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    //		[recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey]; 
    //		[recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
//    NSDictionary *recordSetting =
//    [[NSDictionary alloc] initWithObjectsAndKeys:
//     
//     [NSNumber numberWithFloat:8000.00], AVSampleRateKey,
//     
//     [NSNumber numberWithInt:kAudioFormatiLBC], AVFormatIDKey,
//     
//     [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
//     
//     [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey,
//     
//     nil];
    
        NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
                                       //[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                       [NSNumber numberWithFloat:8000.00], AVSampleRateKey,
                                       [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                       //  [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                       [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                       [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                       [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                       [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                       nil];
    
    //Now that we have our settings we are going to instanciate an instance of our recorder instance.
    //Generate a temp file for use by the recording.
    //This sample was one I found online and seems to be a good choice for making a tmp file that
    //will not overwrite an existing one.
    //I know this is a mess of collapsed things into 1 call.  I can break it out if need be.
    recordedTmpFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
    NSLog(@"Using File called: %@",recordedTmpFile);

    
    //Setup the recorder to use this file and record to it.
    recorder = [[ AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    recorder.meteringEnabled = YES;
    NSLog(@"1");
    //Use the recorder to start the recording.
    //Im not sure why we set the delegate to self yet.  
    //Found this in antother example, but Im fuzzy on this still.
    [recorder setDelegate:self];
    //We call this to start the recording process and initialize 
    //the subsstems so that when we actually say "record" it starts right away.
    [recorder prepareToRecord];
        NSLog(@"2");
    //Start the actual Recording
    [recorder record];
        NSLog(@"3");
    [self startMeterTimer];
    //There is an optional method for doing the recording for a limited time see 
    //[recorder recordForDuration:(NSTimeInterval) 10]
}

- (void)startMeterTimer {
    if (!self.meterTimer) {
        dispatch_queue_t  queue = dispatch_get_global_queue(0, 0);
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC, 0);
        WeakPtr *weakPtr = [[WeakPtr alloc] init];
        weakPtr.weakObj = self;
        dispatch_source_set_event_handler(timer, ^{
            if ([weakPtr.weakObj isKindOfClass:[RecordAudio class]]) {
                RecordAudio *weakRecordAudio = (RecordAudio *)weakPtr.weakObj;
                [weakRecordAudio updateMeter];
            }
        });
        self.meterTimer = timer;
    }
    
    dispatch_resume(self.meterTimer);
}

- (void)stopMeterTimer {
    if (self.meterTimer) {
        dispatch_source_cancel(self.meterTimer);
        self.meterTimer = nil;
    }
}

- (void)updateMeter {
    
    [recorder updateMeters];
    self.averagePower   = [self calculatePower:[recorder averagePowerForChannel:0]];
    self.peakPower      = [self calculatePower:[recorder peakPowerForChannel:0]];
    NSLog(@"peakPower: %f, averagePower: %f", self.peakPower, self.averagePower);
}

- (float)calculatePower:(float)power {
    
    /**
     The current peak power, in decibels, for the sound being recorded.
     A return value of 0 dB indicates full scale, or maximum power;
     a return value of -160 dB indicates minimum power (that is, near silence).
     
     If the signal provided to the audio recorder exceeds ±full scale,
     then the return value may exceed 0 (that is, it may enter the positive range).
     */
    
    float level; // The linear 0.0 .. 1.0 value we need.
    float minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    if (power < minDecibels) {
        level = 0.0f;
    } else if (power >= 0.0f) {
        level = 1.0f;
    } else {
        float root = 2.0f;
        float minAmp = powf(10.0f, 0.05f *minDecibels); // 最小分贝放大
        float inverseAmpRange = 1.0f / (1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * power); // 当前分贝放大
        float adjAmp = (amp - minAmp) *inverseAmpRange; // 最终使用的分贝数
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    return level;
}
@end
