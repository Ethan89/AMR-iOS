//
//  ViewController.m
//  AMRDemo
//
//  Created by Ethan Guo on 2018/3/29.
//  Copyright © 2018年 ebeitech. All rights reserved.
//

#import "ViewController.h"
#import "RecordAudio.h"
#import "SVProgressHUD.h"

@interface ViewController () <RecordAudioDelegate>

@property (strong, nonatomic) RecordAudio *recordAudio;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startRecordAudio:(id)sender {
    NSString *audioFilePath = [self getAudioFilePath];
    NSLog(@"%@", audioFilePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:audioFilePath]) {
        [fileManager removeItemAtPath:audioFilePath error:nil];
    }
    
    [self.recordAudio startRecord];
}

- (IBAction)stopRecordAudio:(id)sender {
    NSURL *audioURL = [self.recordAudio stopRecord];
    NSData *amrAudioData = EncodeWAVEToAMR([NSData dataWithContentsOfURL:audioURL],1,16);
    NSString *audioFilePath = [self getAudioFilePath];
    if ([amrAudioData writeToFile:audioFilePath atomically:YES]) {
        NSLog(@"保存成功");
        NSTimeInterval interval = [RecordAudio getAudioTime:amrAudioData];
        int seconds = (int)interval % 60;
        int minutes = ((int)interval / 60) % 60;
        int hours = (int)interval / 3600;
        NSMutableString *formatTime = [[NSMutableString alloc] init];
        if (hours > 0) {
            [formatTime appendFormat:@"%d°", hours];
        }
        if (minutes > 0) {
            [formatTime appendFormat:@"%d′", minutes];
        }
        [formatTime appendFormat:@"%d″", seconds];
        
        self.timeLabel.text = formatTime;
    }
}

- (IBAction)playAudio:(id)sender {
    
    NSString *audioFilePath = [self getAudioFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:audioFilePath]) {
        NSData *audioData = [NSData dataWithContentsOfFile:audioFilePath];
        [self.recordAudio play:audioData];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"File is not exist"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)RecordStatus:(int)status {
    switch (status) {
        case 0: {
            [SVProgressHUD showWithStatus:@"Playing"];
            break;
        }
        case 1: {
            [SVProgressHUD showSuccessWithStatus:@"Finish"];
            break;
        }
        case 2: {
            [SVProgressHUD showErrorWithStatus:@"Error occur"];
            break;
        }
        default:
            break;
    }
}

- (NSString *)getAudioFilePath {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *audioFilePath = [docDir stringByAppendingPathComponent:@"test.amr"];
    return audioFilePath;
}

#pragma mark - Getters
- (RecordAudio *)recordAudio {
    if (!_recordAudio) {
        _recordAudio = [[RecordAudio alloc] init];
        _recordAudio.delegate = self;
    }
    return _recordAudio;
}
@end
