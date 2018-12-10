//
//  ViewController.m
//  PDFDemo
//
//  Created by Xuzixiang on 2018/11/9.
//  Copyright © 2018 frankxzx. All rights reserved.
//

#import "ViewController.h"
#import "BNHtmlPdfKit.h"

@interface ViewController () <BNHtmlPdfKitDelegate>

@property(nonatomic, strong) BNHtmlPdfKit *pdf;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *bar = [[Foo alloc]init].bar;
    
    // Override point for customization after application launch.
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Header" ofType:@"html"];
    NSString *path2 = [[NSBundle mainBundle]pathForResource:@"BOMView" ofType:@"html"];
    NSString *headerHtmlString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString *contentHtmlString = [NSString stringWithContentsOfFile:path2 encoding:NSUTF8StringEncoding error:nil];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *folderPath = [documentPath stringByAppendingPathComponent:@"pdf"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:folderPath]) {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *localSavedPath = [folderPath stringByAppendingPathComponent:@"render.pdf"];
    
    BNHtmlPdfKit *pdf = [BNHtmlPdfKit saveHtmlAsPdf:contentHtmlString
                                             toFile:localSavedPath
                                     pageHeaderHtml:headerHtmlString
                                     pageFooterHtml:nil
                                            success:^(NSString *filename) {
        
                                            }
                                            failure:^(NSError *error) {
        
                                            }];
    
    self.pdf = pdf;

}


@end
