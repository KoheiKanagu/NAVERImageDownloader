//
//  NAVERImageDownloaderWindowController.h
//  NAVERImageDownloader
//
//  Created by Kohei on 2014/05/08.
//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>
#import <WebKit/WebKit.h>

typedef enum : NSUInteger {
    exportWithOriginalFileName,
    exportWithUniqueFileName,
}ExportFileNameFormat;


@interface NAVERImageDownloaderWindowController : NSWindowController
{
    NSMutableData *receivedDatas;
    
    IBOutlet NSTextField *textField;
    IBOutlet NSTextField *htmlTextField;
    IBOutlet WebView *myWebView;
    
    IBOutlet NSButton *downloadButton;
    IBOutlet NSButton *analyzeThisPageButton;
    IBOutlet NSButton *analyzeAllPageButton;
    IBOutlet NSMatrix *radioMatrix;
    
    IBOutlet NSProgressIndicator *myIndicator;
    IBOutlet NSProgressIndicator *myPageIndicator;
    
    ExportFileNameFormat nameFormat;
    
    NSString *currectURL;
    NSMutableDictionary *downloadImagePageURLs;
}


@end
