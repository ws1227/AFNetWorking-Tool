//
//  NetworkManger.m
//  BestPlayer
//
//  Created by panhongliu on 2016/12/7.
//  Copyright © 2016年 panhongliu. All rights reserved.
//

#import "NetworkManger.h"
#import "NSString+Cache.h"
#import "AFHTTPSessionManager.h"
#import "UIview+toast.h"
#import "MBProgressHUD+LJ.h"
#define KeyWindow       [[UIApplication sharedApplication] keyWindow]

static NSString *NetworkBaseUrl = nil;
static NSString *NetworkErrorcode = nil;

static RequestType  ws_requestType  = RequestTypePlainText;
static ResponseType ws_responseType = ResponseTypeJSON;
static NetworkStatus ws_networkStatus = NetworkStatusReachableViaWiFi;
static BOOL ws_shoulObtainLocalWhenUnconnected = NO;
static NSMutableArray *ws_requestTasks;
static NSMutableArray *down_requestTasks;

static NSTimeInterval ws_timeout = 30.0f;
// 缓存路径
static inline NSString *cachePath() {
    return [NSString cachesPathString];
}
@implementation NetworkManger
+ (NetworkManger *)shareManager {
    static NetworkManger *manger=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manger) {
            manger = [[NetworkManger alloc]init];
            
        }
    });
    return manger;
    
}
+ (void)setTimeout:(NSTimeInterval)timeout {
    ws_timeout = timeout;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (ws_requestTasks == nil) {
            ws_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return ws_requestTasks;
}
+ (NSMutableArray *)alldownTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (down_requestTasks == nil) {
            down_requestTasks = [[NSMutableArray alloc] init];
        }
    });
    
    return down_requestTasks;
}



-(void)setErrorOrRightCode:(NSString *)errorOrRightCode
{
    NetworkErrorcode=errorOrRightCode;
    
}
-(void)setBaseUrl:(NSString *)baseUrl
{
    
    NetworkBaseUrl=baseUrl;
    
}

#pragma mark -- 网络判断 --
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain
{
    ws_shoulObtainLocalWhenUnconnected = shouldObtain;

       
    
    //1.创建网络状态监测管理者
    AFNetworkReachabilityManager *reachability = [AFNetworkReachabilityManager sharedManager];
    [reachability startMonitoring];

    //2.监听改变
    [reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NetworkLog(@"未知");
                ws_networkStatus=NetworkStatusUnknown;
                
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NetworkLog(@"没有网络");
                ws_networkStatus=NetworkStatusNotReachable;

                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NetworkLog(@"3G|4G");
                ws_networkStatus = NetworkStatusReachableViaWWAN;

                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NetworkLog(@"WiFi");
                ws_networkStatus = NetworkStatusReachableViaWiFi;

                break;
            default:
                break;
        }
    }];
    
    
}


+(AFHTTPSessionManager *)getRequstManager
{
    AFHTTPSessionManager *manager = nil;;
    //设置基本的URL
    if (NetworkBaseUrl!= nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:NetworkBaseUrl]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    AFJSONResponseSerializer *response = [AFJSONResponseSerializer serializer];
    //json传送方式  去掉<null>
    response.removesKeysWithNullValues = YES;
    manager.responseSerializer = response;
    switch (ws_requestType) {
        case RequestTypeJSON: {
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        }
        case RequestTypePlainText: {
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    switch (ws_responseType) {
        case ResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case ResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case ResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
   
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json",@"text/html", @"text/plain",nil];
   
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept" ];

    [manager.requestSerializer setTimeoutInterval:ws_timeout];


    return manager;
    

}




#pragma mark -- GET请求 --
+ (void)getNetworkRequestWithUrlString:(NSString *)urlString parameters:(id)parameters isCache:(BOOL)isCache succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail{
    
    [self requestType:NetworkRequestTypeGET url:urlString parameters:parameters isCache:isCache cacheTime:0.0 succeed:succeed fail:fail];
}

#pragma mark -- GET请求 <含缓存时间> --
+ (void)getCacheRequestWithUrlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)time succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail{
    
    [self requestType:NetworkRequestTypeGET url:urlString parameters:parameters isCache:YES cacheTime:time succeed:succeed fail:fail];
}


#pragma mark -- POST请求 --
+ (void)postNetworkRequestWithUrlString:(NSString *)urlString parameters:(id)parameters isCache:(BOOL)isCache succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail{
    
    [self requestType:NetworkRequestTypePOST url:urlString parameters:parameters isCache:isCache cacheTime:0.0 succeed:succeed fail:fail];
}

#pragma mark -- POST请求 <含缓存时间> --
+ (void)postCacheRequestWithUrlString:(NSString *)urlString parameters:(id)parameters cacheTime:(float)time succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail{
    
    [self requestType:NetworkRequestTypePOST url:urlString parameters:parameters isCache:YES cacheTime:time succeed:succeed fail:fail];
}

/**
 *  PUT请求
 *
*/
+ (void)putRequestWithUrlString:(NSString *)urlString parameters:(id)parameters  succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail

{
    [self requestType:NetworkRequestTypePut url:urlString parameters:parameters isCache:NO cacheTime:0.0 succeed:succeed fail:fail];
    
}

/**
 *  Delete请求
 *
 */
+ (void)deleteRequestWithUrlString:(NSString *)urlString parameters:(id)parameters  succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail

{
    [self requestType:NetworkRequestTypeDelete url:urlString parameters:parameters isCache:NO cacheTime:0.0 succeed:succeed fail:fail];
    
}
//取消请求任务

+ (void)cancelRequestWithURL:(NSString *)url {
    if (url == nil) {
        return;
    }
    
    @synchronized(self) {
        
        NetworkLog(@"所有的网络请求：%@",[self allTasks] );
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task isKindOfClass:[NSURLSessionDataTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                NetworkLog(@"被取消的网络请求：%@",task );

                
                [task cancel];
                if ([self allTasks].count>0) {
                    [[self allTasks] removeObject:task];
    
                }
                return;
            }
            
            
        }];
    };
}


//取消所有请求任务
+ (void)cancelAllRequest {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
                [task cancel];
            }
        }];
        
        [[self allTasks] removeAllObjects];
    };
}

/**
 *
 *  取消某个下载任务呀的请求
 *	@param url URL，可以是绝对URL，也可以是path（也就是不包括baseurl）
 */
+ (void)cancelDowntTaskwithURL:(NSString *)url
{
    if (url == nil) {
        return;
    }
    NetworkLog(@"所有的下载的网络请求：%@",[self alldownTasks] );
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
          if ([task isKindOfClass:[NSURLSessionDownloadTask class]]
              ) {
              
              NetworkLog(@"被取消的下载的网络请求：%@",task);
              
                [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    
                }];
              if ([self alldownTasks]>0) {
                  [[self alldownTasks] removeObject:task];

              }
                return;
            }
            
            
        }];
 

    
}

/**
 *
 *	取消所有下载任务请求
 */
+ (void)cancelAllDownTask
{
    
    @synchronized(self) {
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
                
                [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                    
                }];
            }
        }];
        
        [[self alldownTasks] removeAllObjects];
    };
}



//暂停单个下载任务
+(void)suspendDownWithPath:(NSString *)path
{
    
    if (path == nil) {
        return;
    }
    
    @synchronized(self) {
        
        NetworkLog(@"所有的网络请求：%@",[self alldownTasks] );
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            
            if ([task isKindOfClass:[NSURLSessionDownloadTask class]]
                && [task.currentRequest.URL.absoluteString isEqualToString:path]) {
                NetworkLog(@"被停止的的网络下载：%@",task );
                
                
                [task suspend];
            }
        }];
    };
    
}

//暂停所有下载任务
+(void)suspendAllDownTask
{
    
        @synchronized(self) {
        
        NetworkLog(@"所有的下载请求：%@",[self alldownTasks] );
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            
            if ([task isKindOfClass:[NSURLSessionDownloadTask class]]
                ) {
                
                
                [task suspend];
            }
        }];
    };
    
}


//恢复单个下载任务

+(void)resumeDownWithPath:(NSString *)path
{
    if (path == nil) {
        return;
    }
    
    @synchronized(self) {
        
        NetworkLog(@"所有的网络请求：%@",[self alldownTasks] );
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task isKindOfClass:[NSURLSessionDownloadTask class]]
                && [task.currentRequest.URL.absoluteString hasSuffix:path]) {
                NetworkLog(@"被停止的的网络下载：%@",task );
                
                
                [task resume];
            }
        }];
    };
    
}
//恢复所有下载任务

+(void)resumeAllDownTask
{
    @synchronized(self) {
        
        [[self alldownTasks] enumerateObjectsUsingBlock:^(NSURLSessionDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([task isKindOfClass:[NSURLSessionDownloadTask class]]
              ) {
                
                [task resume];
            }
        }];
    };

    
}


#pragma mark -- 网络请求 --
/**
 *  网络请求
 *
 *  @param type       请求类型，get请求/Post请求
 *  @param urlString  请求地址字符串
 *  @param parameters 请求参数
 *  @param isCache    是否缓存
 *  @param time       缓存时间
 *  @param succeed    请求成功回调
 *  @param fail       请求失败回调
 */
+ (void)requestType:(NetworkRequestType)type url:(NSString *)urlString parameters:(id)parameters isCache:(BOOL)isCache cacheTime:(float)time succeed:(void(^)(id data))succeed fail:(void(^)(NSError *error))fail{
    
    NSString *key = [self cacheKey:urlString params:parameters];
    
    NetworkLog(@"请求地址%@参数%@",urlString,parameters);

    if (ws_shoulObtainLocalWhenUnconnected&&(ws_networkStatus==NetworkStatusNotReachable||ws_networkStatus==NetworkStatusUnknown)) {
        if ([CacheDefaults objectForKey:key]) {
            id cacheData = [self cahceResponseWithURL:urlString parameters:parameters];
            if (cacheData) {
                
                if (succeed) {
                    succeed(cacheData);
                    //如果断网了就直接返回没必要再请求了
                    return;
                    
                }
            }
        }
    }
    

    // 判断网址是否加载过，如果没有加载过 在执行网络请求成功时，将请求时间和网址存入UserDefaults，value为时间date、Key为网址
    if ([CacheDefaults objectForKey:key]) {
        // 如果UserDefaults存过网址，判断本地数据是否存在
        id cacheData = [self cahceResponseWithURL:urlString parameters:parameters];
        if (cacheData) {
            // 如果本地数据存在
            // 判断存储时间，如果在规定直接之内，读取本地数据，解析并return，否则将继续执行网络请求
            if (time > 0) {
                NSDate *oldDate = [CacheDefaults objectForKey:key];
                float cacheTime = [[NSString stringNowTimeDifferenceWith:[NSString stringWithDate:oldDate]] floatValue];
                if (cacheTime < time) {
                   
                    if (succeed) {
                        succeed(cacheData);
                    }
                }
            }
        }
    }else{
        // 判断是否开启缓存
        if (isCache) {
            id cacheData = [self cahceResponseWithURL:urlString parameters:parameters];
            if (cacheData) {
                
                if (succeed) {
                    succeed(cacheData);
                }
            }
        }
    }
    
    
    if ([self shareManager].hideMBProgress == NO) {
        
        if ([self shareManager].isSetCustomTip!=nil) {
             [MBProgressHUD showMessage:[NetworkManger shareManager].isSetCustomTip toView:[self activityViewController ].view];
            [self shareManager].isSetCustomTip=nil;
        }
        else{
            [MBProgressHUD showMessage:@"正在加载" toView:[self activityViewController ].view];
        }
       
        
    }else{
        [self shareManager].hideMBProgress=NO;
        
    }

    
    AFHTTPSessionManager *manager = [self getRequstManager];
    NSURLSessionTask *session=nil;
    // 不加上这句话，会报“Request failed: unacceptable content-type: text/plain”错误，因为要获取text/plain类型数据
    if (type == NetworkRequestTypeGET) {
        // GET请求
    session  = [manager GET: [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NetworkLog(@"返回的数据：%@",responseObject);
            [[self allTasks] removeObject:task];

            if (succeed) {
                if ([self isSuccess:responseObject]) {
                    
                    succeed(responseObject);

                    // 请求成功，加入缓存，解析数据
                    if (isCache) {
                       
                        [self cacheResponseObject:responseObject withTime:time  urlString:urlString parameters:parameters];
                    }
                    


                }
                else{
                    
                    [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
                    
                    
                }
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];

            // 请求失败
            if (fail) {
                [self failureTipWithAndTask:task AndError:error];
                
                fail(error);
                
            }
        }];
        
    }   else if  (type == NetworkRequestTypePOST) {
        // POST请求
       session= [manager POST:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
            // 请求的进度
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [[self allTasks] removeObject:task];

            if ([self isSuccess:responseObject]) {
               
                succeed(responseObject);

                // 请求成功，加入缓存，解析数据
                if (isCache) {
                    
                    [self cacheResponseObject:responseObject withTime:time  urlString:urlString parameters:parameters];
                }
                
                
            }
            else{
                
                [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
                
                
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

            // 请求失败
            if (fail) {
                [self failureTipWithAndTask:task AndError:error];

                fail(error);
 

            }
        }];
    }
    
    else if (type==NetworkRequestTypePut)
    {
       
     
      session=  [manager PUT:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
          
          [[self allTasks] removeObject:task];

            if ([self isSuccess:responseObject]) {
                
                succeed(responseObject);
                
                
            }
            else{
                
                [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
                
                
            }

            
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // 请求失败
            if (fail) {
                [self failureTipWithAndTask:task AndError:error];
                
                fail(error);
                
                
            }
        }];
    }
    
    
    else if  (type == NetworkRequestTypeDelete)
    {
       session= [manager DELETE:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           [[self allTasks] removeObject:task];

           if ([self isSuccess:responseObject]) {
                
                succeed(responseObject);
                
                
            }
            else{
                
                [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
                
                
            }
            
            

            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            // 请求失败
            if (fail) {
                [self failureTipWithAndTask:task AndError:error];
                
                fail(error);
                
                
            }
        }];
        
        
    }

    
    [[self allTasks] addObject:session];

    
    
    
}

#pragma mark -- 上传图片 --
+ (void)uploadWithURLString:(NSString *)URLString
                 parameters:(id)parameters
                      model:(UploadImageModel *)model
                   progress:(void (^)(float writeKB, float totalKB)) progress
                    succeed:(void (^)())succeed
                       fail:(void (^)(NSError *error))fail{
    AFHTTPSessionManager *manager = [self getRequstManager];
    [manager POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        // 拼接data到请求体，这个block的参数是遵守AFMultipartFormData协议的。
        NSData *imageData = UIImageJPEGRepresentation(model.image, 1);
        NSString *imageFileName = model.imageName;
        if (imageFileName == nil || ![imageFileName isKindOfClass:[NSString class]] || imageFileName.length == 0) {
            // 如果文件名为空，以时间命名文件名
            imageFileName = [NSString imageFileName];
        }
        [formData appendPartWithFileData:imageData name:model.field fileName:imageFileName mimeType:[NSString imageFieldType]];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        float uploadKB = uploadProgress.completedUnitCount/1024.0;
        float grossKB = uploadProgress.totalUnitCount/1024.0;
        if (progress) {
            progress(uploadKB, grossKB);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NetworkLog(@"上传图片解析：%@",responseObject);
        
        if (succeed) {
            succeed(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // 请求失败
        if (fail) {
            fail(error);
        }
    }];
}

+ (void )uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(void (^)(float writeKB, float totalKB)) progress
                                succeed:(void (^)())succeed
                                   fail:(void (^)(NSError *error))fail
{
    
   
    NSURL *uploadURL= [self getRightUrlWithUrlString:url];
    
    AFHTTPSessionManager *manager = [self getRequstManager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    NSURLSessionTask *session =[manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }

    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    
        [[self allTasks] removeObject:session];
       
        if (!error) {
            
      
        if ([self isSuccess:responseObject]) {
            
            succeed(responseObject);
            
            
        }
        else{
            
            [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
            
            
        }
        
        }
        else{
            fail(error);
              [self showLoadRequestSuccessButAppearErrorWithResponseObject:responseObject];
            
        }
    }];
    

    if (session) {
        [[self allTasks] addObject:session];
    }
    
}

+ (void )downloadWithUrl:(NSString *)url
              saveToPath:(NSString *)saveToPath
                progress:(void (^)(float writeKB, float totalKB)) progress
                 succeed:(void (^)(NSString *panth))succeed
                    fail:(void (^)(NSError *error))fail
{
    
    NSURL *uploadURL= [self getRightUrlWithUrlString:url];
    NetworkLog(@"下载路径URL：%@",uploadURL);
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:uploadURL];
    AFHTTPSessionManager *manager = [self getRequstManager];
    
    NSURLSessionDownloadTask *session =[manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress.completedUnitCount, downloadProgress.completedUnitCount);
            NetworkLog(@"下载路径URL%@\n下载的大小：%lld\n总大小：%lld",uploadURL,downloadProgress.completedUnitCount,downloadProgress.totalUnitCount);

        }

        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:saveToPath];

        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self alldownTasks] removeObject:session];
        if (error == nil) {
            if (succeed) {
                
                    succeed(filePath.absoluteString);
 
                }
        }
        else{
            NetworkLog(@"下载失败了");
         
            [self failureTipWithAndTask:session AndError:error];
            
            fail(error);
            
            
        }
    }];
    
    [session resume];
    if (session) {
        [[self alldownTasks] addObject:session];
    }

}

+(NSURL *)getRightUrlWithUrlString:(NSString *)url
{
    NSURL *uploadURL = nil;
    if (NetworkBaseUrl == nil) {
        uploadURL = [NSURL URLWithString:url];
    } else {
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {

        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", NetworkBaseUrl, url]];
        }
        else{
             uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", url]];
        }
    }
    
    if (uploadURL == nil) {
        NetworkLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    return uploadURL;
    
}

+(BOOL)isSuccess:(id )responseObject
{
    
    [self hideAllMBProgress];

    if (NetworkErrorcode!=nil) {
        if ([responseObject[NetworkErrorcode]intValue] ==1) {
            
            return YES;
        }
        else{
            return NO;
        }

    }
    else{
        //必须设置一个用于标记成功或者失败的字段才知道请求是否成功  resultCount是ViewController苹果那个接口的标记  使用时请设置自己服务器的字段
        //    [NetworkManger shareManager].errorOrRightCode=@"resultCount";

        NSCAssert(NetworkErrorcode != nil, @"未设置标记与成功或者失败的字段");

        return nil;
        
    }
    
   }


//请求失败错误提示
+(void)showLoadRequestSuccessButAppearErrorWithResponseObject:(id )responseObject{
   
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        
    
    NSString *tip=responseObject[@"reason"];
    
    if ([self shareManager].isHideErrorTip==YES) {
        
        
        [self shareManager].isHideErrorTip=NO;
        
    }
    else{
        
        if ([tip  isKindOfClass:[NSNull class]]) {
            [KeyWindow makeToast:@"未知错误"];
            
        }
        else{
            [KeyWindow makeToast:tip];
        }
        
    }
}
    else{
        
        NetworkLog(@"请求结果不是字典类型");
        
    }
    

    
}

//请求失败
+(void)failureTipWithAndTask:(id )task AndError:(NSError *)error
{
    if ([task isKindOfClass:[NSURLSessionDataTask class]]) {
        if ([self allTasks].count>0) {
            [[self allTasks]removeObject:task];
            
        }
 

    }
    else if ([task isKindOfClass:[NSURLSessionDownloadTask class]])
    {
        
        
    }
    
    
    [self hideAllMBProgress];
    
    
    if ([self shareManager].isHideErrorTip==YES) {
        
        
        [self shareManager].isHideErrorTip=NO;
        
    } else{
   
    if (error.code == -1009) {
        [KeyWindow makeToast:@"网络已断开"];
    }else if (error.code == -1005){
        [KeyWindow makeToast:@"网络连接已中断"];
    }else if(error.code == -1001){
        [KeyWindow makeToast:@"请求超时"];
    }else if (error.code == -1003){
        [KeyWindow makeToast:@"未能找到使用指定主机名的服务器"];
    }
    else if (error.code == -999){
        [KeyWindow makeToast:@"请求已取消"];
    }
    else{
        [KeyWindow makeToast:@"数据加载失败"];
        
        NetworkLog(@"-----------暂未定的失败原因---------------\n%@",[NSString stringWithFormat:@"code:%ld %@",error.code,error.localizedDescription]);
        
    }
    }

    
}
+(void)hideAllMBProgress
{
    
    [MBProgressHUD hideAllHUDsForView:[self  activityViewController ].view animated:YES];

}



#pragma mark -- 缓存处理 --
/**
 *  缓存文件夹下某地址的文件名，及UserDefaulets中的key值
 *
 *  @param urlString 请求地址
 *  @param params    请求参数
 *
 *  @return 返回一个MD5加密后的字符串
 */
+ (NSString *)cacheKey:(NSString *)urlString params:(id)params{
    NSString *absoluteURL = [NSString generateGETAbsoluteURL:urlString params:params];
    
    NSString *key = [NSString networkingUrlString_md5:absoluteURL];
    return key;
}

/**
 *  读取缓存
 *
 *  @param url    请求地址
 *  @param params 拼接的参数
 *
 *  @return 数据data
 */
+ (id)cahceResponseWithURL:(NSString *)url parameters:(id)params {
    id cacheData = nil;
    if (url) {
        // 读取本地缓存
        NSString *key = [self cacheKey:url params:params];
        NSString *path = [cachePath() stringByAppendingPathComponent:key];
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            //因为存的是data所以转化为json
            id dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:nil];

            cacheData = dict;
        }
    }
    return cacheData;
}

/**
 *  添加缓存
 *
 *  @param responseObject 请求成功数据
 *  @param urlString      请求地址
 *  @param params         拼接的参数
 */
+ (void)cacheResponseObject:(id)responseObject withTime:(float)time  urlString:(NSString *)urlString parameters:(id)params {
    
   
    NSString *key = [self cacheKey:urlString params:params];
    if (time > 0.0) {
        [CacheDefaults setObject:[NSDate date] forKey:key];
    }
    
    NSString *path = [cachePath() stringByAppendingPathComponent:key];
    [self deleteFileWithPath:path];
    NSData *data = nil;
    NSError *error = nil;

    if ([responseObject isKindOfClass:[NSData class]]) {
        data = responseObject;
        
    } else {
        data = [NSJSONSerialization dataWithJSONObject:responseObject
                                               options:NSJSONWritingPrettyPrinted
                                                 error:&error];

    }

    
    BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    if (isOk) {
        NetworkLog(@"cache file success: %@\n", path);
    } else {
        NetworkLog(@"cache file error: %@\n", path);
    }
}

// 清空缓存
+ (void)clearCaches {
    // 删除CacheDefaults中的存放时间和地址的键值对，并删除cache文件夹
    NSString *directoryPath = cachePath();
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:directoryPath]){
        NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:directoryPath] objectEnumerator];
        NSString *key;
        while ((key = [childFilesEnumerator nextObject]) != nil){
            NetworkLog(@"remove_key ==%@",key);
            [CacheDefaults removeObjectForKey:key];
        }
    }
    if ([manager fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [manager removeItemAtPath:directoryPath error:&error];
        if (error) {
            NetworkLog(@"clear caches error: %@", error);
        } else {
            NetworkLog(@"clear caches success");
        }
    }
}

//单个文件的大小
+ (long long)fileSizeAtPath:(NSString*)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

//遍历文件夹获得文件夹大小，返回多少KB
+ (float)getCacheFileSize{
    NSString *folderPath = cachePath();
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/1024.0;
}


/**
 *  判断文件是否已经存在，若存在删除
 *
 *  @param path 文件路径
 */
+ (void)deleteFileWithPath:(NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath:path];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NetworkLog(@"file deleted success");
        if (err) {
            NetworkLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NetworkLog(@"no file by that name");
    }
}

#pragma mark - 查找当前活动窗口
+(UIViewController *)activityViewController
{
    UIViewController* activityViewController = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if(window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *tmpWin in windows)
        {
            if(tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    NSArray *viewsArray = [window subviews];
    if([viewsArray count] > 0)
    {
        UIView *frontView = [viewsArray objectAtIndex:0];
        
        id nextResponder = [frontView nextResponder];
        
        if([nextResponder isKindOfClass:[UIViewController class]])
        {
            activityViewController = nextResponder;
        }
        else
        {
            activityViewController = window.rootViewController;
        }
    }
    if (activityViewController==nil) {
        activityViewController=window.rootViewController;
        
    }
    
    return activityViewController;
}


@end
