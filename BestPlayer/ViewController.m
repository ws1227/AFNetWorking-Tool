//
//  ViewController.m
//  BestPlayer
//
//  Created by panhongliu on 2016/12/7.
//  Copyright © 2016年 panhongliu. All rights reserved.
//

#import "ViewController.h"
#import "Networking.h"
#define APPID @"1140827531"  //APPID
#import "UIview+Toast.h"
#import "MBProgressHUD.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    //appdelegate里设置了基url
    
    //不显示加载中的提示圈
//    [NetworkManger shareManager].hideMBProgress=YES;
    
    //隐藏错误提示  可以断网测试
//    [NetworkManger shareManager].isHideErrorTip=YES;

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [NetworkManger cancelRequestWithURL:[NSString stringWithFormat:@"/lookup?id=%@",APPID]];
    });
    [NetworkManger getNetworkRequestWithUrlString:[NSString stringWithFormat:@"/lookup?id=%@",APPID] parameters:nil isCache:NO  succeed:^(id data) {



        NSLog(@"数据：%@",data);
        NSArray *resultArray = [data objectForKey:@"results"];

        NSDictionary *resultDict = [resultArray objectAtIndex:0];
        NSString *latestVersion = [resultDict objectForKey:@"version"];//版本
        double latestVersionNum = [latestVersion doubleValue];
        
        //获得当前版本  在info.plist文件中获得
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *currentVersion = [infoDict objectForKey:@"CFBundleVersion"];
        NSLog(@"当前的版本号：%@---网上版本号%f",currentVersion,latestVersionNum);
        double doubleCurrentVersion = [currentVersion doubleValue];
        
        if (doubleCurrentVersion < latestVersionNum)
        {
            NSString *description = [resultDict objectForKey:@"description"];
            NSString *trackViewUrl = [resultDict objectForKey:@"trackViewUrl"];
            

            [self.view makeToast:[NSString stringWithFormat:@"您的应用需要更新\n%@\n：%@",description,trackViewUrl]];
        }
        else{
            
            [self.view makeToast:@"不需要更新了"];

        }

    } fail:^(NSError *error) {
    
        
    }];


    NSString * path =@"https://sdkfiledl.jiguang.cn/JPush-iOS-SDK-2.2.0.zip";

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //暂停一个下载请求
//        [NetworkManger suspendDownWithPath:path];
        //取消一个下载请求
//         [NetworkManger cancelDowntTaskwithURL:path];
        
      //取消所有下载请求
//        [NetworkManger cancelAllDownTask];
        

    });
    
    NSLog(@"下载路径%@",path);

    //初始化进度条
    MBProgressHUD *HUD = [[MBProgressHUD alloc]initWithView:self.view];
    [self.view addSubview:HUD];
    HUD.tag=1000;
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.labelText = @"Downloading...";
    HUD.square = YES;
    [HUD show:YES];
    [NetworkManger downloadWithUrl:@"https://sdkfiledl.jiguang.cn/JPush-iOS-SDK-2.2.0.zip" saveToPath:path progress:^(float writeKB, float totalKB) {
        
        NSLog(@"%f%f",writeKB,totalKB);
        
        CGFloat precent = (CGFloat)writeKB / totalKB;
        HUD.progress = precent;
        
    } succeed:^(NSString *panth){
        
        NSLog(@"下载成功%@",panth);
        [self.view makeToast:@"下载成功"];
        [HUD removeFromSuperview];

        
    } fail:^(NSError *error) {
        NSLog(@"下载失败");
        [HUD removeFromSuperview];


    }];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    NSString * path =@"https://sdkfiledl.jiguang.cn/JPush-iOS-SDK-2.2.0.zip";

    [NetworkManger resumeDownWithPath:path];

    
    //断网测试缓存
//    [NetworkManger cancelRequestWithURL:[NSString stringWithFormat:@"/lookup?id=%@",APPID]];

    

//    [NetworkManger getCacheRequestWithUrlString:[NSString stringWithFormat:@"/lookup?id=%@",APPID] parameters:nil cacheTime:2 succeed:^(id data) {
//        
//        NSLog(@"数据：%@",data);
//    } fail:^(NSError *error) {
//        
//        
//    }];
//
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
