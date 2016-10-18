//
//  FLCarouselView.m
//  FLCarouselVIewDemo
//
//  Created by 冯璐 on 16/8/2.
//  Copyright © 2016年 冯璐. All rights reserved.
//

#import "FLCarouselView.h"
#import "UIView+CGRect.h"
#import <ImageIO/ImageIO.h>

#define kFileManager [NSFileManager defaultManager]

typedef NS_ENUM(NSUInteger, Direction) {
    
    DirectionNone,         // 无方向变化
    DirectionToLeft,         // 向左滑
    DirectionToRight         // 向右滑
    
};

@interface FLCarouselView ()<UIScrollViewDelegate>

//滑动反向
@property (nonatomic, assign) Direction direction;
//底部scrollview
@property (nonatomic, strong) UIScrollView *scrollView;
//当前图片
@property (nonatomic, strong) UIImageView *currentImg;
//下一张图片
@property (nonatomic, strong) UIImageView *nextImg;
//当前索引
@property (nonatomic, assign) NSInteger currentIndex;
//下一个索引
@property (nonatomic, assign) NSInteger nextIndex;
//自动播定时器
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIPageControl *pageControl;

//轮播的图片数组
@property (nonatomic, strong) NSMutableArray *images;
//下载图片的队列
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

static NSString *cachePath = @""; //沙盒缓存路径

@implementation FLCarouselView

+ (void)initialize {
    //创建下载图片存放的位置路径
    cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"FLCarousel"];
    NSLog(@"%@",cachePath);
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir];
    //创建文件夹
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}


// 代码初始化
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpSubviews];
    }
    return self;
}

// 图片数组
- (void)setImgArray:(NSArray *)imgArray{
    if (!imgArray.count) return;
    
    _imgArray = imgArray;
    _images = [NSMutableArray array];
    
    for (int i = 0; i < imgArray.count; i++) {
        if ([imgArray[i] isKindOfClass:[UIImage class]]) {
            // 本地图片直接加入数组加载
            [_images addObject:imgArray[i]];
        }else if ([imgArray[i] isKindOfClass:[NSString class]]){
            //网络图片，先使用占位图，下载完后使用图片
            [_images addObject:[UIImage imageNamed:@"FLPlaceholder"]];
            //下载图片
            [self downloadImageWithIndex:i];
        }
    }
    
    //防止在滚动过程中重新给imageArray赋值时报错
    if (_currentIndex >= _images.count) {
        _currentIndex = _images.count - 1;
    }
    self.currentImg.image = _images[_currentIndex];
    self.pageControl.numberOfPages = _images.count;
    [self layoutSubviews];

}


//懒加载下载queue
- (NSOperationQueue *)downloadQueue {
    if (!_downloadQueue) {
        _downloadQueue = [[NSOperationQueue alloc] init];
    }
    return _downloadQueue;
}


// 布局子视图
- (void)setUpSubviews{
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.backgroundColor = [UIColor yellowColor];
    
    [self addSubview:self.scrollView];
    self.scrollView.delegate = self;
    
    // 两个 UIImageView
    // currentImgView
    self.currentImg = [[UIImageView alloc] init];
    self.currentImg.clipsToBounds = YES;
    [self.scrollView addSubview:self.currentImg];
    
    // nextImgView
    self.nextImg = [[UIImageView alloc] init];
    self.nextImg.clipsToBounds = YES;
    [self.scrollView addSubview:self.nextImg];
    
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.backgroundColor = [UIColor blackColor];
    self.pageControl.alpha = 0.5;
    [self addSubview:self.pageControl];
    [self bringSubviewToFront:self.pageControl];
    
    // 添加scrollView滑动方向的观察者
    [self addObserver:self forKeyPath:@"direction" options:(NSKeyValueObservingOptionNew) context:nil];
    
    // 默认开启图片自动缓存
    self.isAutoCache = YES;
    
}

// 布局子视图
- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    [self setScrollViewContentSize];
    //开启定时器
    [self startTimer];
}

// 设置scrollView的contentSize
- (void)setScrollViewContentSize{
    
    if (self.images.count > 1) {
        self.scrollView.contentSize = CGSizeMake(self.width * 3, 0);
        self.scrollView.contentOffset = CGPointMake(self.width, 0);
        self.currentImg.frame = CGRectMake(self.width, 0, self.width, self.height);
        
        CGFloat width = [self.images count] * 25;
        CGFloat height = 30;
        self.pageControl.frame = CGRectMake(CGRectGetWidth(self.frame) - width - 40, CGRectGetHeight(self.frame) - height - 20, width, height);
        self.pageControl.numberOfPages = [self.images count];

    }
}

#pragma mark -------- scrollView 代理方法 ---------
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (CGSizeEqualToSize(CGSizeZero, scrollView.contentSize)) return;
    // 判断滑动方向
    CGFloat offsetX = scrollView.contentOffset.x;
    self.direction = offsetX > self.width ? DirectionToLeft : DirectionToRight;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    int index = self.scrollView.contentOffset.x / self.width;
    //等于1表示最后没有滚动，返回不做任何操作
    if (index == 1) return;
    [self prepareNextImage];
    NSLog(@"%ld,%ld",self.currentIndex, self.nextIndex);
    self.pageControl.currentPage = self.currentIndex;
}

- (void)prepareNextImage{
    //当前图片索引改变
    self.currentIndex = self.nextIndex;
    self.currentImg.frame = CGRectMake(self.width, 0, self.width, self.height);
    self.currentImg.image = self.nextImg.image;
    self.scrollView.contentOffset = CGPointMake(self.width, 0);
}

// 实现观察者方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    // 未改变直接返回
    if (change[NSKeyValueChangeNewKey] == change[NSKeyValueChangeOldKey]) return;
    // 向右侧滑动时
    if ([change[NSKeyValueChangeNewKey] integerValue] == DirectionToRight) {
        self.nextImg.frame = CGRectMake(0, 0, self.width, self.height);
        self.nextIndex = self.currentIndex - 1;
        if (self.nextIndex < 0) {
           self.nextIndex = self.images.count - 1;
        }
    // 向左侧滑动时
    }else if ([change[NSKeyValueChangeNewKey] integerValue] == DirectionToLeft){
        self.nextImg.frame = CGRectMake(CGRectGetMaxX(self.currentImg.frame), 0, self.width, self.height);
        self.nextIndex = (self.currentIndex + 1) % self.imgArray.count;
    }
    // 从数组中去下一张图片
    self.nextImg.image = self.images[self.nextIndex];
}

// 开启定时器
- (void)startTimer {
    
    // 只有一张图片时
    if (self.images.count <= 1) return;
    if (!self.timer) {
        self.timer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

// 跳转到下一张图片（定时器操作）
- (void)nextPage {
    
    [self.scrollView setContentOffset:CGPointMake(self.width * 2, 0) animated:YES];
    
    NSLog(@"%ld",self.currentIndex);
    
    // pageControl操作
    if (self.currentIndex == [self.images count]-1) {
        self.currentIndex = -1;
    }
    self.pageControl.currentPage = self.currentIndex + 1;
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    int index = scrollView.contentOffset.x / self.width;
    if (index == 1) return; //等于1表示最后没有滚动，返回不做任何操作
    [self prepareNextImage];
}

//停止定时器
- (void)stopTimer {
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

// 手动拖动时停止定时器
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

// 手动拖完后是否重启定时器
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    decelerate = self.isStartTimer;
    if (decelerate) {
        [self startTimer];
    }
}

- (void)downloadImageWithIndex:(NSInteger)index{
    //获取imgArr每个Url
    NSString *urlString = _imgArray[index];
    NSString *imgName = [urlString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    // 获取图片最终位置
    NSString *imgPath = [cachePath stringByAppendingPathComponent:imgName];
    
    //如果开启的缓存功能，先从沙盒中取图片
    if (_isAutoCache) {
        NSData *imgData = [NSData dataWithContentsOfFile:imgPath];
        if (imgData) {
            _images[index] = getImageWithData(imgData);
            return;
        }
    }
    
    //下载图片
    NSBlockOperation *downloadBlock = [NSBlockOperation blockOperationWithBlock:^{
       
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if (!data) return;
        UIImage *image = getImageWithData(data);
        //如果下载的是图片
        if (image) {
            _images[index] = image;
            if (_currentIndex == index) {
                [_currentImg performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
            }
            // 如果开启自动缓存，保存图片
            if (_isAutoCache) {
                [data writeToFile:imgPath atomically:YES];
            }
        }
    }];
    //加入下载队列
    [self.downloadQueue addOperation:downloadBlock];
}

// 清除沙盒中的图片缓存
- (void)clearDiskMemory {
    NSLog(@"清除缓存成功");
    NSArray *cacheMemory = [kFileManager contentsOfDirectoryAtPath:cachePath error:nil];
    for (NSString *fileName in cacheMemory) {
        [kFileManager removeItemAtPath:[cachePath stringByAppendingPathComponent:fileName] error:nil];
    }
}


#pragma mark - 根据data获取图片 --- C函数
UIImage* getImageWithData(NSData *data){
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    //开辟空间
    size_t count = CGImageSourceGetCount(imageSource);
    //非gif时
    if (count <= 1) {
        CFRelease(imageSource);
        return [[UIImage alloc] initWithData:data];
    }else { // gif图片
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, i, NULL
                                                               );
            if (!image) {
                continue;
            }
            duration += durationWithSourceAtIndex(imageSource, i);
            [images addObject:[UIImage imageWithCGImage:image]];
            CGImageRelease(image);
        }
        if (!duration) {
            duration = 0.1 * count;
        }
        
        CFRelease(imageSource);
        return [UIImage animatedImageWithImages:images duration:duration];
        
    }
    
    return 0;
}

#pragma mark - 获取每一帧图片的时长 -- C 函数
float durationWithSourceAtIndex(CGImageSourceRef source, NSUInteger index){
    
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    NSDictionary *properties = (__bridge NSDictionary *)(propertiesRef);
    NSDictionary *gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];
    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) {
        duration = delayTime.floatValue;
    }else{
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) {
            duration = delayTime.floatValue;
        }
    }
    CFRelease(propertiesRef);
    return duration;
}



@end
