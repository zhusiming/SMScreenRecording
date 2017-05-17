//
//  ViewController.m
//  SMScreenRecording
//
//  Created by 朱思明 on 16/8/23.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import "ViewController.h"
#import "SMScreenRecording.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

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

- (IBAction)start:(id)sender {
    
    [[SMScreenRecording shareManager] startScreenRecordingWithScreenView:self.view failureBlock:^(NSError *error) {
    }];
}

- (IBAction)stop:(id)sender {
    // 播放视频
    //    movieVc=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:kMoviePath]];
    //    //弹出播放器
    //    [self presentMoviePlayerViewControllerAnimated:movieVc];
    
//    [self.view.window endScreenRecordingWithFinishBlock:^(NSError *error, NSString *videoPath) {
//        if (error == nil) {
//            NSLog(@"path:%@",videoPath);
//            // 播放视频
//            MPMoviePlayerViewController *movieVc=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:kMoviePath]];
//            //弹出播放器
//            [self presentMoviePlayerViewControllerAnimated:movieVc];
//        }
//    }];
    
    [[SMScreenRecording shareManager] endScreenRecordingWithFinishBlock:^(NSError *error, NSString *videoPath) {
        // 播放视频
        MPMoviePlayerViewController *movieVc= [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:videoPath]];
        //弹出播放器
        [self presentMoviePlayerViewControllerAnimated:movieVc];
    }];
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch.view == _movieView) {
        _movieView.center = [touch locationInView:self.view];
    }
}



@end
