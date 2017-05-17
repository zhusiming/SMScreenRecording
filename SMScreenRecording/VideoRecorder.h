//
//  VideoRecorder.h
//  Sandbox
//
//  Created by kuwabara yuki on 2015/04/28.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^DrawProcess)();

@class VideoRecorder;

@protocol VideoRecorderDelegate
- (void)onSaveSucceeded:(VideoRecorder*)videoRecorder path:(NSString*)videoPath;
@end

@interface VideoRecorder : NSObject

+ (VideoRecorder*)getInstance;
+ (void)prepare:(UIViewController*)viewController drawProcess:(DrawProcess)func;
- (void)prepare:(UIViewController*)viewController drawProcess:(DrawProcess)func;

- (void)start;
- (void)stop;

@property (nonatomic, readonly) NSString* outputPath;
@property (nonatomic, readonly) NSURL*    outputURL;

@end
