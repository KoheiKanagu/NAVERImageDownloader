//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import "KKNeverDownloader.h"

@implementation KKNeverDownloader

//画像ページURLを検索
-(NSArray *)samplingImagePageWithURL:(NSURL *)url singlePage:(BOOL)single
{
    int i=1;
    NSMutableArray *urls = [[NSMutableArray alloc]init];
    
    while(1){
        NSString *string = @"";
        
        if(single){
            string = [NSString stringWithFormat:@"%@", url];
        }else{
            //ページ番号削除して1から
            NSArray *hoge = [[NSString stringWithFormat:@"%@", url] componentsSeparatedByString:@"?"];
            string = [NSString stringWithFormat:@"%@?page=%d", hoge[0], i++];
        }
        NSString *fileContents = [NSString stringWithContentsOfURL:[NSURL URLWithString:string]
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
        NSArray *array = [self formalWithRule:@"<p class=\"mdMTMWidget01ItemImg01View.*<a href=\"(.*)\""
                                     contents:fileContents];
        
        //重複を探し、最終ページに到達してるのか検査
        int same=0;
        for(NSString *newURL in array){
            for(NSString *savedURL in urls){
                if([newURL isEqualToString:savedURL]){
                    same++;
                }
            }
        }
        if(same == array.count){
            break;
        }
        [urls addObjectsFromArray:array];
    }
    return [NSArray arrayWithArray:urls];
}


//ページから画像URL抽出
-(NSString *)analyzeImageURLWith:(NSURL *)url
{
    NSString *imagePage = [NSString stringWithContentsOfURL:url
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
    NSArray *imageOriginURLs = [self formalWithRule:@"<p class=\"mdMTMEnd01Img01\"><a href=\"(.*)\" target=\"_blank\">"
                                          contents:imagePage];
    return imageOriginURLs[0];
}



//正規表現
-(NSArray *)formalWithRule:(NSString *)rule contents:(NSString *)contents
{
    NSMutableArray *results = [[NSMutableArray alloc]init];
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:rule
                                                                           options:0
                                                                             error:&error];
    if(error){
        NSLog(@"%@", error.description);
        return nil;
    }
    NSArray *matches = [regex matchesInString:contents
                                      options:0
                                        range:NSMakeRange(0, contents.length)];
    for(NSTextCheckingResult *match in matches){
        [results addObject:[contents substringWithRange:[match rangeAtIndex:1]]];
    }
    
    return [NSArray arrayWithArray:results];
}

@end
