//
//  ViewController.h
//  SMScreenRecording
//
//  Created by 朱思明 on 16/8/23.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
@interface ViewController : GLKViewController
{
    __weak IBOutlet UIView *_movieView;
}
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end

