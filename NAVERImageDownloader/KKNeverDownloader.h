//  Copyright (c) 2014年 KoheiKanagu. All rights reserved.

#import <Foundation/Foundation.h>

@interface KKNeverDownloader : NSObject

-(NSArray *)samplingImagePageWithURL:(NSURL *)url singlePage:(BOOL)single;
-(NSArray *)formalWithRule:(NSString *)rule contents:(NSString *)contents;
-(NSString *)analyzeImageURLWith:(NSURL *)url;


@end
