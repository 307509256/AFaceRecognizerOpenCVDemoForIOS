//
//  ViewController.h
//  XCOpenCV
//
//  Created by JohnnyPan on 16/1/1.
//  Copyright © 2016年 JohnnyPan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/objdetect/objdetect_c.h>


@interface ViewController : UIViewController

-(IplImage *)CreateIplImageFromUIImage:(UIImage *)image;

@end

