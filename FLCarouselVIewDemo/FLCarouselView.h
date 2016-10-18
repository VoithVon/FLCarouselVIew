//
//  FLCarouselView.h
//  FLCarouselVIewDemo
//
//  Created by 冯璐 on 16/8/2.
//  Copyright © 2016年 冯璐. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLCarouselView : UIView

// 轮播图片数组
@property (nonatomic, strong) NSArray *imgArray;
// 手动拖拉视图后，是否要继续自动轮播 (默认为：NO)
@property (nonatomic, assign) BOOL isStartTimer;
// 是否自动缓存
@property (nonatomic, assign) BOOL isAutoCache;

//清除缓存
- (void)clearDiskMemory;

@end
