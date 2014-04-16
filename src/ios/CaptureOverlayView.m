//
//  CaptureOverlayView.m
//  NXTransport
//
//  Created by Jonathan Nunez Aguin on 17/03/2014.
//
//

#import "CaptureOverlayView.h"

#define kTextMargin 10

static const int MIN_FRAME_WIDTH = 240;
static const int MIN_FRAME_HEIGHT = 100;
static const int MAX_FRAME_WIDTH = 1800;
static const int MAX_FRAME_HEIGHT = 400;

@implementation CaptureOverlayView{
    CAShapeLayer *_outline;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        self.clipsToBounds = YES;
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectZero];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        toolbar.translucent = YES;
        
        NSMutableArray *items = [NSMutableArray arrayWithCapacity: 1];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:) ];
        
        [items addObject: cancelButton];        
        
        [toolbar setItems:items animated:NO];
        
        [toolbar sizeToFit];
        CGFloat toolbarHeight  = [toolbar frame].size.height;
        CGFloat rootViewHeight = CGRectGetHeight(self.bounds);
        CGFloat rootViewWidth  = CGRectGetWidth(self.bounds);
        CGRect  rectArea       = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
        
        [toolbar setFrame:rectArea];
        
        [self addSubview: toolbar];
        
        _outline = [CAShapeLayer new];
        _outline.strokeColor = [[[UIColor redColor] colorWithAlphaComponent:0.8] CGColor];
        _outline.lineWidth = 2.0;
        _outline.fillColor = [[UIColor clearColor] CGColor];
        [self.layer addSublayer:_outline];
    }
    return self;
}

- (void)cancel:(id)sender {
	if (self.delegate != nil) {
		[self.delegate cancelled];
	}
}

- (void)setFoundMatchWithTopLeftPoint:(CGPoint)topLeftPoint topRightPoint:(CGPoint)topRightPoint bottomLeftPoint:(CGPoint)bottomLeftPoint bottomRightPoint:(CGPoint)bottomRightPoint{
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    UIBezierPath *path = [UIBezierPath new];
    // Start at the first corner
    [path moveToPoint: topLeftPoint];
    
    // Now draw lines around the corners
    [path addLineToPoint: topRightPoint];
    [path addLineToPoint: bottomRightPoint];
    [path addLineToPoint: bottomLeftPoint];
    
    // And join it back to the first corner
    [path addLineToPoint: topLeftPoint];
    
    _outline.path = [path CGPath];
    
    [CATransaction commit];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect inContext:(CGContextRef)context {
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y);
	CGContextStrokePath(context);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(int) findDesiredDimensionInRangeFor: (int) resolution min:(int) hardMin max: (int) hardMax {
    int dim = 7 * resolution / 8;
    if (dim < hardMin) {
        return hardMin;
    }
    if (dim > hardMax) {
        return hardMax;
    }
    return dim;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
-(CGRect) cropRect{
    
    CGSize screenResolution = self.bounds.size;
    
    int width = [self findDesiredDimensionInRangeFor:screenResolution.width min:MIN_FRAME_WIDTH max:MAX_FRAME_WIDTH];
    int height = (int) (width * 0.15);
    
    int leftOffset = (screenResolution.width - width) / 2;
    int topOffset = (screenResolution.height - height) / 2;
    
    CGRect framingRect = CGRectMake(leftOffset, topOffset, width, height);
    
    return framingRect;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGPoint)map:(CGPoint)point {
    CGPoint center;
    center.x = [self cropRect].size.width/2;
    center.y = [self cropRect].size.height/2;
    float x = point.x - center.x;
    float y = point.y - center.y;
    int rotation = 90;
    switch(rotation) {
        case 0:
            point.x = x;
            point.y = y;
            break;
        case 90:
            point.x = -y;
            point.y = x;
            break;
        case 180:
            point.x = -x;
            point.y = -y;
            break;
        case 270:
            point.x = y;
            point.y = -x;
            break;
    }
    point.x = point.x + center.x;
    point.y = point.y + center.y;
    return point;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
    
	CGContextRef c = UIGraphicsGetCurrentContext();
    
	CGFloat white[4] = {1.0f, 1.0f, 1.0f, 1.0f};
	CGContextSetStrokeColor(c, white);
	CGContextSetFillColor(c, white);
	[self drawRect:[self cropRect] inContext:c];
	
	CGContextSaveGState(c);
    
    NSString *message = NSLocalizedStringWithDefaultValue(@"OverlayView displayed message", nil, [NSBundle mainBundle], @"Place a barcode inside the viewfinder rectangle to scan it.", @"Place a barcode inside the viewfinder rectangle to scan it.");
    
    UIFont *font = [UIFont systemFontOfSize:15];
    CGSize constraint = CGSizeMake(rect.size.width  - 2 * kTextMargin, [self cropRect].origin.y);
    CGSize displaySize = [message sizeWithFont:font constrainedToSize:constraint];
    CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2 , [self cropRect].origin.y - displaySize.height, displaySize.width, displaySize.height);
    [message drawInRect:displayRect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
}

- (void)reset{
    [_outline removeAllAnimations];
    [self setNeedsLayout];
}


@end
