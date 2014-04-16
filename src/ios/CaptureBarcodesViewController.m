//
//  CaptureBarcodesViewController.m
//  NXTransport
//
//  Created by Jonathan Nunez Aguin on 17/03/2014.
//
//

#import "CaptureBarcodesViewController.h"

@interface CaptureBarcodesViewController ()<CaptureCancelDelegate>

- (void)startCapture;
- (void)stopCapture;

- (AVCaptureVideoOrientation) convertOrientation: (UIInterfaceOrientation) from;

@property (nonatomic, strong) NSDate *lastDetectionDate;
@property (nonatomic, assign) NSTimeInterval quietPeriodAfterMatch;

@end

@implementation CaptureBarcodesViewController{
    NSTimer *_timer;
    BOOL _scanning;
    BOOL _wasScanning;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    beepSound = -1;
    self.quietPeriodAfterMatch = 2.0;
}

- (void)dealloc {
    if (beepSound) {
        AudioServicesDisposeSystemSoundID(beepSound);
    }
    
    [self stopCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear: animated];
    
    _highlightView = [[CaptureOverlayView alloc] initWithFrame: self.view.bounds];
    _highlightView.delegate = self;
    [self.view addSubview:_highlightView];
    
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = self.view.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _prevLayer.connection.videoOrientation = [self convertOrientation: self.interfaceOrientation];
    [self.view.layer addSublayer:_prevLayer];
    
    [self.view bringSubviewToFront:_highlightView];
    
    [self startCapture];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_highlightView removeFromSuperview];
    [self stopCapture];
}

#pragma mark - Cancel delegate

- (void)cancelled {
    [_highlightView removeFromSuperview];
    
    [self stopCapture];
    
    if (self.delegate != nil){
        [self.delegate captureControllerDidCancel: self];
    }
}

- (BOOL)isInQuietPeriod {
    return self.lastDetectionDate != nil && (-[self.lastDetectionDate timeIntervalSinceNow]) <= self.quietPeriodAfterMatch;
}

- (CGPoint)pointFromArray:(NSArray *)points atIndex:(NSUInteger)index {
    NSDictionary *dict = [points objectAtIndex:index];
    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)dict, &point);
    
    return [_highlightView convertPoint:point fromView:self.view];
}

#pragma mark - AVCaptureOutput

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([self isInQuietPeriod]) {
        return;
    }
    
    for(AVMetadataObject *current in metadataObjects) {
        if([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            if(self.delegate != nil) {
                AVMetadataMachineReadableCodeObject *readableObject = (AVMetadataMachineReadableCodeObject *) current;
                NSString *scannedValue = [readableObject stringValue];
                NSString *scannedFormat = current.type;
                NSArray *corners = readableObject.corners;
                
                if (corners.count == 4 && scannedValue != nil) {
                    
                    CGPoint topLeftPoint = [self pointFromArray:corners atIndex:0];
                    CGPoint bottomLeftPoint = [self pointFromArray:corners atIndex:1];
                    CGPoint bottomRightPoint = [self pointFromArray:corners atIndex:2];
                    CGPoint topRightPoint = [self pointFromArray:corners atIndex:3];
                    
                    if (CGRectContainsPoint(_highlightView.bounds, topLeftPoint) &&
                        CGRectContainsPoint(_highlightView.bounds, topRightPoint) &&
                        CGRectContainsPoint(_highlightView.bounds, bottomLeftPoint) &&
                        CGRectContainsPoint(_highlightView.bounds, bottomRightPoint))
                    {
                        [self stopCapture];
                        _timer = [NSTimer scheduledTimerWithTimeInterval:self.quietPeriodAfterMatch target:self selector:@selector(startCapture) userInfo:nil repeats:NO];
                        self.lastDetectionDate = [NSDate date];
                        
                        [_highlightView setFoundMatchWithTopLeftPoint:topLeftPoint
                                                        topRightPoint:topRightPoint
                                                      bottomLeftPoint:bottomLeftPoint
                                                     bottomRightPoint:bottomRightPoint];
                        if (beepSound) {
                            AudioServicesPlaySystemSound(beepSound);
                        }
                        [self.delegate captureController:self didScanResult:scannedValue format: scannedFormat];
                    }
                }
            }
        }
    }
}

- (void)startCapture {
    if (!_scanning) {
        _scanning = YES;
        [_highlightView reset];
        [_session startRunning];
    }
    
}

- (void)stopCapture {

    if (_scanning) {
        _scanning = NO;
        [_timer invalidate];
        _timer = nil;
        [_session stopRunning];
    }
}


#pragma mark -
#pragma mark UIViewController Rotate

-(AVCaptureVideoOrientation) convertOrientation: (UIInterfaceOrientation) from{
    
    AVCaptureVideoOrientation newOrientation;
    
    switch (from) {
        case UIInterfaceOrientationPortrait:
            newOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            newOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeRight:
            newOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            newOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            newOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    return newOrientation;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger ret = 0;
    
    /*if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait]) {
        ret = ret | (1 << UIInterfaceOrientationPortrait);
    }
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
        ret = ret | (1 << UIInterfaceOrientationPortraitUpsideDown);
    }*/
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeRight);
    }
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeLeft);
    }
    
    return ret;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(captureController:shouldAutorotateToInterfaceOrientation:)]){
        return [self.delegate captureController: self shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    [CATransaction begin];
    
    _prevLayer.connection.videoOrientation = [self convertOrientation: orientation];
    [_prevLayer layoutSublayers];
    _prevLayer.frame = self.view.bounds;
    
    [_highlightView setNeedsDisplay];
    
    [CATransaction commit];
    [super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}

#pragma mark -
#pragma mark Setter sound

- (void)setSoundToPlay:(NSURL *)aSoundToPlay
{
    if (_soundToPlay != aSoundToPlay) {
        _soundToPlay = aSoundToPlay;
        
        OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)_soundToPlay, &beepSound);
        if (error != kAudioServicesNoError) {
            NSLog(@"Problem loading soundToPlay");
        }
    }
}

#pragma mark -
#pragma mark Touches

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)evt
{
    UITouch *touch=[touches anyObject];
    CGPoint pt= [touch locationInView:self.view];
    [self focus:pt];
    
}

- (void) focus:(CGPoint) aPoint;
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([device isFocusPointOfInterestSupported] &&
       [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        double screenWidth = screenRect.size.width;
        double screenHeight = screenRect.size.height;
        double focus_x = aPoint.x/screenWidth;
        double focus_y = aPoint.y/screenHeight;
        if([device lockForConfiguration:nil]) {
            [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                [device setExposureMode:AVCaptureExposureModeAutoExpose];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark -
#pragma mark Tourch

- (void) setTourch:(BOOL) aStatus;
{
  	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ( [device hasTorch] ) {
        if ( aStatus ) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
    }
    [device unlockForConfiguration];
}


@end
