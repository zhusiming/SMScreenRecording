//
//  SMScreenRecording.h
//  SMScreenRecording
//
//  Created by 朱思明 on 2017/5/13.
//  Copyright © 2017年 朱思明. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^FinishBlock) (NSError *error, NSString *videoPath);
typedef void(^FailureBlock) (NSError *error);

// 录屏保存位置
#define kMoviePath ([NSHomeDirectory() stringByAppendingPathComponent:@"Documents/screen.mp4"])

// 录屏倍数
//#define kScreenScale ([UIScreen mainScreen].scale)
#define kScreenScale (2)
// 视频录制每秒的帧数
#define kFrames (25)

@interface SMScreenRecording : NSObject
{
    // timer对象
    NSTimer *_timer;
    // timer线程
    NSThread *_timer_thread;
    // 获取截屏队列
    dispatch_queue_t _concurrent_getImage_queue;
    dispatch_queue_t _serial_writeVideo_queue;
    // 数据流写入对象
    AVAssetWriter *_videoWriter;
    AVAssetWriterInput *_writerInput;
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
    // 需要录制视频的视图
    UIView *_screenView;
    // 记录录制帧数
    int _frames_number;
    CVPixelBufferPoolRef _outputBufferPool;
    CGColorSpaceRef _rgbColorSpace;
    
    // 开始录制时间
    double _startTime;
}
// 录制失败回调
@property(nonatomic, copy)FailureBlock failureBlock;
@property(nonatomic, copy)FinishBlock finishBlock;

/*
 *  单例方法
 */
+ (SMScreenRecording *)shareManager;

/*
 *  开始录制屏幕
 *
 *  params: 指定视图的填充位置，可以录制指定区域
 */
- (void)startScreenRecordingWithScreenView:(UIView *)screenView failureBlock:(FailureBlock)failureBlock;

/*
 *  停止录制屏幕
 *
 *  return: 视频地址
 */
- (void)endScreenRecordingWithFinishBlock:(FinishBlock) finishBlock;

@end
