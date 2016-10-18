//
//  ViewController.m
//  FLCarouselVIewDemo
//
//  Created by 冯璐 on 16/8/2.
//  Copyright © 2016年 冯璐. All rights reserved.
//

#import "ViewController.h"
#import "FLCarouselView.h"
//#import "NextViewController.h"


@interface ViewController ()

@property (nonatomic, strong) FLCarouselView *carouselView;

@property (nonatomic, strong) NSMutableArray *imgArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.carouselView = [[FLCarouselView alloc] initWithFrame:CGRectMake(0, 50, self.view.frame.size.width, 200)];
    [self.view addSubview:self.carouselView];
    
    
    self.carouselView.isStartTimer = YES;
    
    UIButton *networkBtn = [UIButton buttonWithType:(UIButtonTypeSystem)];
    networkBtn.frame = CGRectMake(100, 300, 100, 30);
    [networkBtn setTitle:@"含网络图片" forState:(UIControlStateNormal)];
    [networkBtn addTarget:self action:@selector(loadNetworkPicture) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:networkBtn];
    
    UIButton *localBtn = [UIButton buttonWithType:(UIButtonTypeSystem)];
    localBtn.frame = CGRectMake(100, 359, 100, 30);
    [localBtn setTitle:@"本地图片" forState:(UIControlStateNormal)];
    [localBtn addTarget:self action:@selector(loadLocalPicture) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:localBtn];

    
}

- (void)loadNetworkPicture{
    //网络图片资源
    NSArray *arr = @[@"http://pic39.nipic.com/20140226/18071023_162553457000_2.jpg",@"http://photo.l99.com/source/11/1330351552722_cxn26e.gif"];
    self.carouselView.imgArray = arr;
}

- (void)loadLocalPicture{
    self.carouselView.imgArray = self.imgArr;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.carouselView clearDiskMemory];
}



// 资源图片数组
- (NSMutableArray *)imgArr {
    
    if (!_imgArr) {
        
        _imgArr = [NSMutableArray array];
        for (int i = 0; i < 11; i++) {
            
            NSString *imageName = [NSString stringWithFormat:@"yuzui%d.jpg",i];
            UIImage *img = [UIImage imageNamed:imageName];
            [_imgArr addObject:img];
        }
    }
    return _imgArr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
