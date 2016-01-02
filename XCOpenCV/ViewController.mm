//
//  ViewController.m
//  XCOpenCV
//
//  Created by JohnnyPan on 16/1/1.
//  Copyright © 2016年 JohnnyPan. All rights reserved.
//



#import "ViewController.h"



@interface ViewController ()
{
    cv::Mat cvImage;
}
@property (nonatomic,weak)IBOutlet UIImageView * opencvImageView;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.opencvImageView.frame = self.view.frame;
    [self opencvFaceDetect];
}
-(void) imageEdge
{
    UIImage * opencvImage = [UIImage imageNamed:@"linyuner"];
    
    UIImageToMat(opencvImage, cvImage);
    if (!cvImage.empty()) {
        
        cv::Mat grayImage;
        cv::cvtColor(cvImage, grayImage, CV_RGBA2GRAY);
        
        cv::GaussianBlur(grayImage, grayImage, cv::Size(5,5), 1.2,1.2);
        // Calculate edges with Canny
        cv::Mat edges;
        cv::Canny(grayImage, edges, 0, 60);
        // Fill image with white color
        cvImage.setTo(cv::Scalar::all(255));
        // Change color on edges
        cvImage.setTo(cv::Scalar(0,128,255,255),edges);
        // Convert cv::Mat to UIImage* and show the resulting image
        self.opencvImageView.image = MatToUIImage(cvImage);
        
    }

}

- (void) opencvFaceDetect  {
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    UIImage * img = [UIImage imageNamed:@"linyuner"];
    if(img) {
        //[self.view bringSubviewToFront:self.indicator];
        //[self.indicator startAnimating];  //由于人脸检测比较耗时，于是使用加载指示器
        NSLog(@"begin");
        cvSetErrMode(CV_ErrModeParent);
        IplImage *image = [self CreateIplImageFromUIImage:img];
        
        IplImage *grayImg = cvCreateImage(cvGetSize(image), IPL_DEPTH_8U, 1); //先转为灰度图
        cvCvtColor(image, grayImg, CV_BGR2GRAY);
        
        //将输入图像缩小4倍以加快处理速度
        int scale = 4;
        IplImage *small_image = cvCreateImage(cvSize(image->width/scale,image->height/scale), IPL_DEPTH_8U, 1);
        cvResize(grayImg, small_image);
        
        //加载分类器
        NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2" ofType:@"xml"];
        CvHaarClassifierCascade* cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
        CvMemStorage* storage = cvCreateMemStorage(0);
        cvClearMemStorage(storage);
        
        //关键部分，使用cvHaarDetectObjects进行检测，得到一系列方框
        CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage ,1.1, 9, CV_HAAR_DO_CANNY_PRUNING, cvSize(0,0), cvSize(0, 0));
        
        NSLog(@"faces:%d",faces->total);
        cvReleaseImage(&small_image);
        cvReleaseImage(&image);
        cvReleaseImage(&grayImg);
        
        //创建画布将人脸部分标记出
        CGImageRef imageRef = img.CGImage;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef contextRef = CGBitmapContextCreate(NULL, img.size.width, img.size.height,8, img.size.width * 4,colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
        
        CGContextDrawImage(contextRef, CGRectMake(0, 0, img.size.width, img.size.height), imageRef);
        
        CGContextSetLineWidth(contextRef, 4);
        CGContextSetRGBStrokeColor(contextRef, 1.0, 0.0, 0.0, 1);
        
        //对人脸进行标记，如果isDoge为Yes则在人脸上贴图
        for(int i = 0; i < faces->total; i++) {
       //     NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
            
            // Calc the rect of faces
            CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
            CGRect face_rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(cvrect.x*scale, cvrect.y*scale , cvrect.width*scale, cvrect.height*scale));
            
//            if(isDoge) {
//                CGContextDrawImage(contextRef, face_rect, [UIImage imageNamed:@"doge.png"].CGImage);
//            } else {
                CGContextStrokeRect(contextRef, face_rect);
//            }
            
        //    [pool release];
        }
        
        self.opencvImageView.image = [UIImage imageWithCGImage:CGBitmapContextCreateImage(contextRef)];
        CGContextRelease(contextRef);
        CGColorSpaceRelease(colorSpace);
        
        cvReleaseMemStorage(&storage);
        cvReleaseHaarClassifierCascade(&cascade);
    }
     NSLog(@"end");
   // [pool release];
   // [self.indicator stopAnimating];
}
-(IplImage *)CreateIplImageFromUIImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return iplimage;
}
@end
