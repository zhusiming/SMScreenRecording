//
//  ViewController.m
//  SMScreenRecording
//
//  Created by 朱思明 on 16/8/23.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import "ViewController.h"
#import "UIView+SMScreenRecording.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()
{
    //    MPMoviePlayerViewController *movieVc;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _movieView.frame = CGRectMake(100, 100, 100, 100);
    _movieView.backgroundColor = [UIColor grayColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    label.text = @"测试";
    [_movieView addSubview:label];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

- (IBAction)start:(id)sender {
    
    [self.view.window startScreenRecordingWithCapInsets:UIEdgeInsetsMake(64, 0, 0, 0) failureBlock:^(NSError *error) {
        NSLog(@"失败了");
    }];
    
}

- (IBAction)stop:(id)sender {
    // 播放视频
    //    movieVc=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:kMoviePath]];
    //    //弹出播放器
    //    [self presentMoviePlayerViewControllerAnimated:movieVc];
    
    [self.view.window endScreenRecordingWithFinishBlock:^(NSError *error, NSString *videoPath) {
        if (error == nil) {
            NSLog(@"path:%@",videoPath);
            // 播放视频
            MPMoviePlayerViewController *movieVc=[[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:kMoviePath]];
            //弹出播放器
            [self presentMoviePlayerViewControllerAnimated:movieVc];
        }
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
