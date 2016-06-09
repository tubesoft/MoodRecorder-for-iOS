//
//  DrawResultPlotView.m
//  ArcheryPoints
//
//  Created by Takatomo INOUE on 2013/11/21.
//  Copyright (c) 2013年 Takatomo INOUE. All rights reserved.
//

#import "DrawResultPlotView.h"

NSArray *locations;

@implementation DrawResultPlotView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setLocations:(NSArray*) locationArray {
    locations = locationArray;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    CGFloat imageViewWidth = 280;
    for (int i=0; i<[locations count]; i++) {
        NSValue *value = [locations objectAtIndex:i];
        CGPoint coodinate = [value CGPointValue];
        float xValue = coodinate.x*8/7;
        float yValue = coodinate.y*8/7;
        [[UIColor colorWithRed:(float)i/(float)[locations count] green:0.0 blue:1.0 alpha:0.2] setFill];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextFillEllipseInRect(context, CGRectMake(xValue - 10, yValue -10, 20, 20));
    }
    
}


@end
