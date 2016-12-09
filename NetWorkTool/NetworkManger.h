//
//  NetworkManger.h
//  BestPlayer
//
//  Created by panhongliu on 2016/12/7.
//  Copyright © 2016年 panhongliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Networking.h"
#import "UploadImageModel.h"
#define openHttpsSSL YES
typedef NS_ENUM(NSInteger, NetworkRequestType) {
    NetworkRequestTypeGET,  // GET请求
    NetworkRequestTypePOST,  // POST请求
    NetworkRequestTypePut,  // Put请求
    NetworkRequestTypeDelete,  // Delete请求
    
    
};

typedef NS_ENUM(NSUInteger, ResponseType) {
    ResponseTypeJSON = 1, // 默认
    ResponseTypeXML  = 2,
    ResponseTypeData = 3
};

typedef NS_ENUM(NSUInteger, RequestType) {
    RequestTypeJSON = 1, // 默认
    RequestTypePlainText  = 2 // 普通text/html
};

typedef NS_ENUM(NSInteger, NetworkStatus) {
    NetworkStatusUnknown          = -1,//未知网络
    NetworkStatusNotReachable     = 0,//网络无连接
    NetworkStatusReachableViaWWAN = 1,//2，3，4G网络
    NetworkStatusReachableViaWiFi = 2,//WIFI网络
};
@interface NetworkManger : NSObject
//设置基础的url
@property(nonatomic,strong)NSString *baseUrl;
//设置后台返回数据的用于标示正确或者错误的字段
@property(nonatomic,copy)NSString * errorOrRightCode;

//是否隐藏提示框
@property(nonatomic,assign)BOOL hideMBProgress;
//是否在请求失败后隐藏默认的"网络加载失败" 提示框
@property(nonatomic,assign)BOOL isHideErrorTip;
//请求提示默认是“正在加载” 可以替换自定义提示文字
@property(nonatomic,copy)NSString * isSetCustomTip;

+ (NetworkManger *)shareManager ;

/**
 *	设置请求超时时间，默认为60秒
 *
 *	@param timeout 超时时间
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 *	当检查到网络异常时，是否从从本地提取数据。默认为NO。 
 *	@param shouldObtain	YES/NO
 */
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain;

/**
 *
 *  取消某个请求
 *	@param url URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/**
 *
 *	取消所有请求
 */
+ (void)cancelAllRequest;


/**
 *
 *  取消某个下载任务
 *	@param url URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+ (void)cancelDowntTaskwithURL:(NSString *)url;

/**
 *
 *	取消所有下载任务请求
 */
+ (void)cancelAllDownTask;

/**
 *
 *	暂停单个下任务
 *  下载路径
 */
+(void)suspendDownWithPath:(NSString *)path;

/**
 *
 *	暂停所有下载任务
 */

+(void)suspendAllDownTask;



/**
 *
 *	开始恢复下载某个任务
 *  下载路径
 */
+(void)resumeDownWithPath:(NSString *)path;


/**
 *
 *	开始恢复下载所有任务
 */
+(void)resumeAllDownTask;





/**
 *  Get请求 <若开启缓存，先读取本地缓存数据，再进行网络请求>
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param isCache    是否开启缓存
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)getNetworkRequestWithUrlString:(NSString *)urlString parameters:(id)parameters isCache:(BOOL)isCache succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;

/**
 *  Get请求 <在缓存时间之内只读取缓存数据，不会再次网络请求，减少服务器请求压力。缺点：在缓存时间内服务器数据改变，缓存数据不会及时刷新>
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param time       缓存时间（单位：分钟）
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)getCacheRequestWithUrlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)time succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;

/**
 *  Post请求 <若开启缓存，先读取本地缓存数据，再进行网络请求，>
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param isCache    是否开启缓存机制
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)postNetworkRequestWithUrlString:(NSString *)urlString parameters:(id)parameters isCache:(BOOL)isCache succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;

/**
 *  Post请求 <在缓存时间之内只读取缓存数据，不会再次网络请求，减少服务器请求压力。缺点：在缓存时间内服务器数据改变，缓存数据不会及时刷新>
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param time       缓存时间（单位：分钟）
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)postCacheRequestWithUrlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)time succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;

/**
 *  PUT请求
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)putRequestWithUrlString:(NSString *)urlString parameters:(id)parameters  succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;

/**
 *  Delete请求
 *
 *  @param urlString  请求地址
 *  @param parameters 拼接的参数
 *  @param succeed    请求成功
 *  @param fail       请求失败
 */
+ (void)deleteRequestWithUrlString:(NSString *)urlString parameters:(id)parameters  succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail;



/**
 *  上传图片
 *
 *  @param URLString  请求地址
 *  @param parameters 拼接的参数
 *  @param model      要上传的图片model
 *  @param progress   上传进度(writeKB：已上传多少KB, totalKB：总共多少KB)
 *  @param succeed    上传成功
 *  @param fail       上传失败
 */
+ (void)uploadWithURLString:(NSString *)URLString
                 parameters:(id)parameters
                      model:(UploadImageModel *)model
                   progress:(void (^)(float writeKB, float totalKB)) progress
                    succeed:(void (^)())succeed
                       fail:(void (^)(NSError *error))fail;


/**
 *
 *	上传文件操作
 *
 *	@param url						上传路径
 *	@param uploadingFile	待上传文件的路径
 *	@param progress			上传进度
 *	@param succeed				上传成功回调
 *	@param fail					上传失败回调
 *
 */
+ (void )uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(void (^)(float writeKB, float totalKB)) progress
                                          succeed:(void (^)())succeed
                                          fail:(void (^)(NSError *error))fail;


/*!
 *
 *  下载文件
 *
 *  @param url           下载URL
 *  @param saveToPath    下载到哪个路径下
 *  @param progress 下载进度
 *  @param succeed       下载成功后的回调
 *  @param fail       下载失败后的回调
 */
+ (void )downloadWithUrl:(NSString *)url
              saveToPath:(NSString *)saveToPath
                progress:(void (^)(float writeKB, float totalKB)) progress
                 succeed:(void (^)(NSString *panth))succeed
                    fail:(void (^)(NSError *error))fail;




/**
 *  清理缓存
 */
+ (void)clearCaches;

/**
 *  获取网络缓存文件大小
 *
 *  @return 多少KB
 */
+ (float)getCacheFileSize;

@end
