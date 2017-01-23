//
//  ViewController.h
//  SMScreenRecording
//
//  Created by 朱思明 on 16/8/23.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
{
    __weak IBOutlet UIView *_movieView;
}
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end

