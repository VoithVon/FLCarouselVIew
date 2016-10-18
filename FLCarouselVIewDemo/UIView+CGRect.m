//
//  UIView+CGRect.m
//  FLCarouselVIewDemo
//
//  Created by 冯璐 on 16/8/22.
//  Copyright © 2016年 冯璐. All rights reserved.
//

#import "UIView+CGRect.h"

@implementation UIView (CGRect)

- (CGFloat)width{
    return self.frame.size.width;
}

- (CGFloat)height{
    return self.frame.size.height;
}

- (CGFloat)x{
    return self.bounds.origin.x;
}

- (CGFloat)y{
    return self.bounds.origin.y;
}
@end
