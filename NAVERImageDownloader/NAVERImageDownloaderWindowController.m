//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import "NAVERImageDownloaderWindowController.h"

@implementation NAVERImageDownloaderWindowController

-(id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        downloadImagePageURLs = [[NSMutableDictionary alloc]init];
        knd = [[KKNeverDownloader alloc]init];
    }
    return self;
}


#pragma mark - Web
-(IBAction)enterKey:(id)sender
{
    NSTextField *text = (NSTextField *)sender;
    [myWebView setMainFrameURL:[text stringValue]];
}

-(void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    currectURL = sender.mainFrameURL;
    [htmlTextField setStringValue:currectURL];
    
    [myPageIndicator startAnimation:nil];
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [myPageIndicator stopAnimation:nil];
}


#pragma mark - Radio
-(IBAction)radioButton:(id)sender
{
    NSMatrix *matrix = (NSMatrix *)sender;
    switch ([matrix selectedColumn]) {
        case 0:
            NSLog(@"origin");
            nameFormat = exportWithOriginalFileName;
            break;
            
        case 1:
            NSLog(@"unique");
            nameFormat = exportWithUniqueFileName;
            break;
            
        default:
            break;
    }
}


#pragma mark - Analyze
-(IBAction)analyzeThisPage:(id)sender
{
    [myPageIndicator startAnimation:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSArray *array = [knd samplingImagePageWithURL:[NSURL URLWithString:[htmlTextField stringValue]]
                                            singlePage:YES];
        [myPageIndicator stopAnimation:nil];
        
        [self initAnalyze:array];
        [textField setStringValue:[NSString stringWithFormat:@"%ld枚の画像を予約", [downloadImagePageURLs allKeys].count]];
    });
}

-(IBAction)analyzeAllPage:(id)sender
{
    [myPageIndicator startAnimation:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        NSArray *array = [knd samplingImagePageWithURL:[NSURL URLWithString:[htmlTextField stringValue]]
                                            singlePage:NO];
        [myPageIndicator stopAnimation:nil];
        
        [self initAnalyze:array];
        [textField setStringValue:[NSString stringWithFormat:@"%ld枚の画像を予約", [downloadImagePageURLs allKeys].count]];
    });
}

-(void)initAnalyze:(NSArray *)array
{
    [myIndicator setDoubleValue:0];
    [downloadButton setEnabled:YES];
    
    for(NSString *url in array){
        [downloadImagePageURLs setObject:@""
                                  forKey:url];
    }
}


#pragma mark - Download
-(IBAction)startDownloadButton:(id)sender
{
    [myIndicator setDoubleValue:0];
    [downloadButton setEnabled:NO];
    [analyzeAllPageButton setEnabled:NO];
    [analyzeThisPageButton setEnabled:NO];
    [radioMatrix setEnabled:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        [self startDownload];
    });
}

-(void)startDownload
{
    NSString *filePath = [NSString stringWithFormat:@"%@/Downloads/NaverImages", NSHomeDirectory()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:filePath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    NSArray *array = [downloadImagePageURLs allKeys];
    if(!array.count){
        NSAlert *alert = [NSAlert alertWithMessageText:@"確認"
                                         defaultButton:@"閉じる"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"予約画像がありません"];
        [alert beginSheetModalForWindow:self.window
                      completionHandler:nil];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(3);
    
    for(__block int i=0; i<array.count; i++){
        NSString *urlString = array[i];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            
            @autoreleasepool{
                NSString *imageUrlString = [knd analyzeImageURLWith:[NSURL URLWithString:urlString]];
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrlString]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(i < array.count){
                        [textField setStringValue:[imageUrlString lastPathComponent]];
                    }else{
                        [textField setStringValue:@"ダウンロード完了"];
                    }
                });
                
                NSMutableString *fullPath = [NSMutableString stringWithFormat:@"%@/", filePath];
                
                switch (nameFormat) {
                    case exportWithOriginalFileName:
                        [fullPath appendString:[imageUrlString lastPathComponent]];
                        break;
                        
                    case exportWithUniqueFileName:{
                        NSString *md5 = [self createMD5:imageUrlString];
                        [fullPath appendFormat:@"%@.%@", md5, [imageUrlString pathExtension]];
                        break;
                    }
                        
                    default:
                        break;
                }
                [data writeToFile:fullPath
                       atomically:NO];
            }
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [myIndicator setDoubleValue:(double)i/(double)array.count*100];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [downloadButton setEnabled:YES];
        [analyzeAllPageButton setEnabled:YES];
        [analyzeThisPageButton setEnabled:YES];
        [radioMatrix setEnabled:YES];
    });
}


-(void)downloadWithURLString:(NSString *)urlString exportFilePath:(NSString *)filePath
{
    NSString *imageUrlString = [knd analyzeImageURLWith:[NSURL URLWithString:urlString]];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrlString]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [textField setStringValue:[imageUrlString lastPathComponent]];
    });
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", filePath, [imageUrlString lastPathComponent]];
    [data writeToFile:fullPath
           atomically:NO];
}




#pragma mark - Other
-(NSString *)createMD5:(NSString *)string
{
    const char *constChar = [string UTF8String];
    unsigned char md5_result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(constChar, (CC_LONG)strlen(constChar), md5_result);
    
    NSString *hex_str = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                         md5_result[0], md5_result[1],
                         md5_result[2], md5_result[3],
                         md5_result[4], md5_result[5],
                         md5_result[6], md5_result[7],
                         md5_result[8], md5_result[9],
                         md5_result[10], md5_result[11],
                         md5_result[12], md5_result[13],
                         md5_result[14], md5_result[15]];
    return hex_str;
}


@end
