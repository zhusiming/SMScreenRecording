//
//  VideoRecorder.m
//  Sandbox
//
//  Created by kuwabara yuki on 2015/04/28.
//
//

#import "VideoRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface VideoRecorder()
{
    UIViewController* viewController;
    
    CADisplayLink* displayLink;
    
    CGSize sizeVideo;
    CGSize sizeSourcePixel;
    
    CFAbsoluteTime timeOfFirstFrame;
    
    AVAssetWriter*                        writer;
    AVAssetWriterInput*                   input;
    AVAssetWriterInputPixelBufferAdaptor* adapter;
    
    GLubyte* rawBytesForImage;
    
    CVPixelBufferRef          renderTarget;
    CVOpenGLESTextureCacheRef rawDataTextureCache;
    
    GLuint dataFramebuffer;
    GLint  defaultFrameBuffer;
}

@property (readwrite, copy) DrawProcess drawFunc;

@end

@implementation VideoRecorder

@dynamic outputPath, outputURL;
@synthesize drawFunc;

static NSString* baseDir;
static NSURL* videoOutputURL;

static VideoRecorder* _instance = nil;

+ (VideoRecorder*)getInstance
{
    if (_instance == nil) {
        _instance = [[VideoRecorder alloc] init];
    }
    
    return _instance;
}

+ (BOOL)supportsFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return (CVOpenGLESTextureCacheCreate != NULL);
#endif
}

+ (void)prepare:(UIViewController*)viewController drawProcess:(DrawProcess)func
{
    [[VideoRecorder getInstance] prepare:viewController drawProcess:func];
}

- (void)prepare:(UIViewController*)viewController_ drawProcess:(DrawProcess)func
{
    NSAssert([VideoRecorder supportsFastTextureUpload], @"can not perform CVOpenGLESTextureCacheCreate ");
    
    viewController = viewController_;
    drawFunc       = func;
    
    baseDir          = nil;
    videoOutputURL   = nil;
    
    sizeVideo       = viewController.view.layer.bounds.size;
    sizeSourcePixel = CGSizeMake(sizeVideo.width * viewController.view.layer.contentsScale, sizeVideo.height * viewController.view.layer.contentsScale);
}

- (void)start
{
    [self initializeWritingModules];
    
    [self createFrameBufferObject];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(appendFrame)];
    [displayLink setFrameInterval:1];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}
- (void)initializeWritingModules
{
    NSError* error = nil;
    writer = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:AVFileTypeMPEG4 error:&error];
    
    NSDictionary* assetWriterInputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInt:sizeVideo.width],  AVVideoWidthKey,
                                              [NSNumber numberWithInt:sizeVideo.height], AVVideoHeightKey,
                                              nil];
    
    input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:assetWriterInputSettings];
    input.expectsMediaDataInRealTime = YES;
    input.transform = CGAffineTransformMakeScale(1.0, -1.0); // fix upside down
    
    NSDictionary* sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                 [NSNumber numberWithInt:sizeVideo.width],  kCVPixelBufferWidthKey,
                                                 [NSNumber numberWithInt:sizeVideo.height], kCVPixelBufferHeightKey,
                                                 nil];
    
    adapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input
                                                                               sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    [writer addInput:input];
    
    
    glGetIntegerv(GL_FRAMEBUFFER_BINDING,  &defaultFrameBuffer);
    glGenFramebuffers(1, &dataFramebuffer);
    
    timeOfFirstFrame = CFAbsoluteTimeGetCurrent();
    
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
}
- (void)cleanUp
{
    rawBytesForImage = NULL;
    
    adapter = nil;
    input   = nil;
    writer  = nil;
}

- (void)stop
{
    [displayLink invalidate];
    displayLink = nil;
    
    [input markAsFinished];
    
    [writer finishWritingWithCompletionHandler:^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:self.outputPath]) {
//            [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:self.outputURL completionBlock:^(NSURL *assetURL, NSError *error){
//                NSLog(@"saved : %@ %@", assetURL, error);
//                [self cleanUp];
//            }];
        }
    }];
}

- (bool)createFrameBufferObject
{
    // output frame bufffer object
    glBindFramebuffer(GL_FRAMEBUFFER, dataFramebuffer);
    
    CVReturn r;
    
    r = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &rawDataTextureCache);
    
    if (r != kCVReturnSuccess) {
        NSLog(@"CVOpenGLESTextureCacheCreate %d", r);
        return false;
    }
    
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0,
                                               &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1,
                                                             &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    r = CVPixelBufferCreate(kCFAllocatorDefault, (int)sizeSourcePixel.width, (int)sizeSourcePixel.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
    if (r != kCVReturnSuccess) {
        NSLog(@"CVPixelBufferCreate %d", r);
        return false;
    }
    
    CVOpenGLESTextureRef renderTexture;
    r = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                     rawDataTextureCache,
                                                     renderTarget,
                                                     NULL, // texture attributes
                                                     GL_TEXTURE_2D,
                                                     GL_RGBA, // opengl format
                                                     (int)sizeSourcePixel.width,
                                                     (int)sizeSourcePixel.height,
                                                     GL_BGRA, // native iOS format
                                                     GL_UNSIGNED_BYTE,
                                                     0,
                                                     &renderTexture);
    if (r != kCVReturnSuccess) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d", r);
        return false;
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
    
    return true;
}

- (void)appendFrame
{
    if (![self beforeDraw]) return;
    
    [self drawInFrame];
    
    [self afterDraw];
}

- (bool)beforeDraw
{
    if (!input.readyForMoreMediaData)
        return false;
    
    glBindFramebuffer(GL_FRAMEBUFFER, dataFramebuffer);
    
    return true;
}

- (void)afterDraw
{
    CFTimeInterval elapsed = CFAbsoluteTimeGetCurrent() - timeOfFirstFrame;
    
    CVPixelBufferLockBaseAddress(renderTarget, 0);
    [adapter appendPixelBuffer:renderTarget withPresentationTime:CMTimeMake(elapsed * 600, 600)];
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
}


- (void)drawInFrame
{
    self.drawFunc();
}

+ (NSString*)fileBaseDir
{
    if (baseDir != nil)
        return baseDir;
    
    NSString* documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    baseDir = documentDirectory;
    
    return baseDir;
}

- (NSString*)outputPath
{
    return self.outputURL.path;
}

- (NSURL*)outputURL
{
    if (videoOutputURL != nil)
        return videoOutputURL;
    
    NSString* pathToMovie = [NSString stringWithFormat:@"%@/%@", [VideoRecorder fileBaseDir], @"rec_video.mp4"];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:pathToMovie])
        [fileManager removeItemAtPath:pathToMovie error:nil];
    
    
    videoOutputURL = [NSURL fileURLWithPath:pathToMovie];
    
    return videoOutputURL;
}

@end
