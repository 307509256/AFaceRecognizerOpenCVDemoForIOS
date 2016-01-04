//
//  ViewController.m
//  XCOpenCV
//
//  Created by JohnnyPan on 16/1/1.
//  Copyright © 2016年 JohnnyPan. All rights reserved.
//



#import "ViewController.h"



@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    cv::Mat cvImage;
}
@property (nonatomic,weak)IBOutlet UIImageView * opencvImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


@property (weak, nonatomic) IBOutlet UIButton *selectPic;


@end

@implementation ViewController

- (IBAction)selectPictureClick:(UIButton *)sender {
    
    [self chooseModeGetPic];
}

-(void) chooseModeGetPic
{
    UIAlertController *  actionSheet = [ UIAlertController alertControllerWithTitle:@"select" message:@"choose the way you got picture" preferredStyle:UIAlertControllerStyleActionSheet];
   // UIAlertAction * actionSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
      UIAlertAction*  Sheet = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self selectPiture];
        }];
        UIAlertAction*  Sheet2 = [UIAlertAction actionWithTitle:@"从相机获取" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction*  Sheet3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [actionSheet addAction:Sheet];
        [actionSheet addAction:Sheet2];
        [actionSheet addAction:Sheet3];
    }else
    {
       
        UIAlertAction*  Sheet2 = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self selectPiture];
        }];
        UIAlertAction*  Sheet3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [actionSheet addAction:Sheet2];
        [actionSheet addAction:Sheet3];
    }
    [self presentViewController:actionSheet animated:YES completion:^{
        
    }];
    
    
}

-(void) selectPiture
{
  
    UIImagePickerController * pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.allowsEditing = YES;
    pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:pickerController animated:YES completion:^{
        
    }];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    
    
    
    NSData * imageData = UIImageJPEGRepresentation(image , 0.5);
    
    NSString  * path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"newImage.png"];
    [imageData writeToFile:path atomically:NO];
    self.opencvImageView.image = nil;
   // dispatch_queue_t  backGround = dispatch_queue_create("backGround", NULL);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self opencvFaceDetect:path];
    });
    
}
-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    
    self.opencvImageView.frame = self.view.frame;
    self.activityIndicator.hidden = YES;
    NSLog(@"%@",NSHomeDirectory());
    
   }
-(void) imageEdge
{
    UIImage * opencvImage = [UIImage imageNamed:@"newImage"];
    
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

- (void) opencvFaceDetect:(NSString *)path
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  //  UIImage * img = [UIImage imageNamed:@"newImage"];
    
    UIImage * img = [[UIImage alloc ] initWithContentsOfFile:path];
    if(img) {
        //[self.view bringSubviewToFront:self.indicator];
        //[self.indicator startAnimating];  //由于人脸检测比较耗时，于是使用加载指示器
        NSLog(@"begin");
        cvSetErrMode(CV_ErrModeParent);
        IplImage *image = [self CreateIplImageFromUIImage:img];
        
        IplImage *grayImg = cvCreateImage(cvGetSize(image), IPL_DEPTH_8U, 1); //先转为灰度图
        cvCvtColor(image, grayImg, CV_BGR2GRAY);
        
        //将输入图像缩小4倍以加快处理速度
        int scale = 1;
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
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
            self.opencvImageView.image = [UIImage imageWithCGImage:CGBitmapContextCreateImage(contextRef)];

        });
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
