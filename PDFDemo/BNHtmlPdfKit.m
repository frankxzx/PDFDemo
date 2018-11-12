//
//  BNHtmlPdfKit.m
//
//  Created by Brent Nycum.
//  Copyright (c) 2013 Brent Nycum. All rights reserved.
//

#import "BNHtmlPdfKit.h"

#define PPI 72
#define BNSizeMakeWithPPI(width, height) CGSizeMake(width * PPI, height * PPI)
#define HeaderWebViewTag 100
#define ContentWebViewTag 101
#define FooterWebViewTag 102


#pragma mark - BNHtmlPdfKitPageRenderer Interface

@interface BNHtmlPdfKitPageRenderer : UIPrintPageRenderer

@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, strong) UIWebView *pageHeader;
@property (nonatomic, strong) UIWebView *pageFooter;

@property(nonatomic, assign) NSRange pageRange;

@end


#pragma mark - BNHtmlPdfKitPageRenderer Implementation

@implementation BNHtmlPdfKitPageRenderer

- (CGRect)paperRect {
    return UIGraphicsGetPDFContextBounds();
}

- (CGRect)printableRect {
    return [self paperRect];
}

- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)headerRect {
    if (self.pageHeader) {
        [self.pageHeader setFrame:headerRect];
        UIImage *image = [self imageFromWebView:self.pageHeader];
        [image drawInRect:headerRect];
    }
}

//计算字符绘制的起始坐标
CGPoint computeStartPoint(CGRect rect,CGSize size) {
    CGFloat startX = (rect.size.width  - size.width) / 2 + rect.origin.x;
    CGFloat startY = (rect.size.height - size.height) / 2 + rect.origin.y;
    return CGPointMake(startX, startY);
}

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)footerRect {
    if (self.pageFooter) {
        [self.pageFooter setFrame:footerRect];
        UIImage *image = [self imageFromWebView:self.pageFooter];
        [image drawInRect:footerRect];
    }
    
//    //1. 页脚(header) 添加背景
//    [[UIColor colorWithWhite:0.8 alpha:1.0] setFill];
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextAddRect(ctx, footerRect);
//    CGContextFillPath(ctx);
    
    //2. 添加文字信息
    NSString *footerString = [NSString stringWithFormat:@"Page  %ld / %ld", pageIndex+1, self.numberOfPages];
//    #808080
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : [UIColor grayColor],
                                 NSFontAttributeName : [UIFont systemFontOfSize:16]
                                 };
    
    CGSize stringSize = [footerString sizeWithAttributes:attributes];
    CGPoint startPoint = computeStartPoint(footerRect, stringSize);
    [footerString drawAtPoint:startPoint withAttributes:attributes];
}

- (UIImage *)imageFromWebView:(UIWebView *)webView {
    CGSize webSize = webView.frame.size;
    CGSize size = CGSizeMake(floor(webSize.width)-1, floor(webSize.height));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [webView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)prepareForDrawingPages:(NSRange)range {
    self.pageRange = range;
    [super prepareForDrawingPages:range];
}

@end


#pragma mark - BNHtmlPdfKit Extension

@interface BNHtmlPdfKit () <UIWebViewDelegate>

- (CGSize)_sizeFromPageSize:(BNPageSize)pageSize;

- (void)_timeout;
- (void)_savePdf;

@property (nonatomic, copy) NSString *outputFile;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIWebView *headerWebView;
@property (nonatomic, strong) UIWebView *footerWebView;

@property (nonatomic, copy) void (^dataCompletionBlock)(NSData *pdfData);
@property (nonatomic, copy) void (^fileCompletionBlock)(NSString *pdfFileName);
@property (nonatomic, copy) void (^failureBlock)(NSError * error);

@property(nonatomic, assign) BOOL isHeaderFinishLoad;
@property(nonatomic, assign) BOOL isFooterFinishLoad;
@property(nonatomic, assign) BOOL isContentFinishLoad;

@end

#pragma mark - BNHtmlPdfKit Implementation

@implementation BNHtmlPdfKit

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url success:(void (^)(NSData *pdfData))completion failure:(void (^)(NSError *error))failure {
    
    return [BNHtmlPdfKit saveUrlAsPdf:url pageSize:[BNHtmlPdfKit defaultPageSize] isLandscape:NO success:completion failure:failure];
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url pageSize:(BNPageSize)pageSize success:(void (^)(NSData *pdfData))completion failure:(void (^)(NSError *error))failure {
    
    return [BNHtmlPdfKit saveUrlAsPdf:url pageSize:pageSize isLandscape:NO success:completion failure:failure];
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url pageSize:(BNPageSize)pageSize isLandscape:(BOOL)landscape success:(void (^)(NSData *pdfData))completion failure:(void (^)(NSError *error))failure {
    
    BNHtmlPdfKit *pdfKit = [[BNHtmlPdfKit alloc] initWithPageSize:pageSize isLandscape:landscape];
    pdfKit.dataCompletionBlock = completion;
    pdfKit.failureBlock = failure;
    [pdfKit saveUrlAsPdf:url toFile:nil];
    return pdfKit;
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url toFile:(NSString *)filename success:(void (^)(NSString *filename))completion failure:(void (^)(NSError *error))failure {
    
    return [BNHtmlPdfKit saveUrlAsPdf:url toFile:filename pageSize:[BNHtmlPdfKit defaultPageSize] isLandscape:NO success:completion failure:failure];
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url toFile:(NSString *)filename pageSize:(BNPageSize)pageSize success:(void (^)(NSString *filename))completion failure:(void (^)(NSError *error))failure {
    
    return [BNHtmlPdfKit saveUrlAsPdf:url toFile:filename pageSize:pageSize isLandscape:NO success:completion failure:failure];
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url toFile:(NSString *)filename pageSize:(BNPageSize)pageSize isLandscape:(BOOL)landscape success:(void (^)(NSString *filename))completion failure:(void (^)(NSError *error))failure {
    
    BNHtmlPdfKit *pdfKit = [[BNHtmlPdfKit alloc] initWithPageSize:pageSize isLandscape:landscape];
    pdfKit.fileCompletionBlock = completion;
    pdfKit.failureBlock = failure;
    [pdfKit saveUrlAsPdf:url toFile:filename];
    return pdfKit;
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url customPageSize:(CGSize)pageSize success:(void (^)(NSData *pdfData))completion failure:(void (^)(NSError *error))failure {
    
    BNHtmlPdfKit *pdfKit = [[BNHtmlPdfKit alloc] initWithCustomPageSize:pageSize];
    pdfKit.dataCompletionBlock = completion;
    pdfKit.failureBlock = failure;
    [pdfKit saveUrlAsPdf:url toFile:nil];
    return pdfKit;
    
}

+ (BNHtmlPdfKit *)saveUrlAsPdf:(NSURL *)url toFile:(NSString *)filename customPageSize:(CGSize)pageSize success:(void (^)(NSString *filename))completion failure:(void (^)(NSError *error))failure {
    
    BNHtmlPdfKit *pdfKit = [[BNHtmlPdfKit alloc] initWithCustomPageSize:pageSize];
    pdfKit.fileCompletionBlock = completion;
    pdfKit.failureBlock = failure;
    [pdfKit saveUrlAsPdf:url toFile:filename];
    return pdfKit;
    
}

+ (BNHtmlPdfKit *)saveHtmlAsPdf:(NSString *)contentHtml
                        toFile:(NSString *)filename
                pageHeaderHtml:(NSString *)headerHtml
                pageFooterHtml:(NSString *)footerHtml
                       success:(void (^)(NSString *filename))completion
                       failure:(void (^)(NSError *error))failure {
    
    BNHtmlPdfKit *pdfKit = [[BNHtmlPdfKit alloc] init];
    pdfKit.fileCompletionBlock = completion;
    pdfKit.failureBlock = failure;
    [pdfKit saveHtmlAsPdf:contentHtml
               pageHeader:headerHtml
               pageFooter:footerHtml
                   toFile:filename];
    return pdfKit;
}

#pragma mark - Initializers

- (id)init {
    if (self = [super init]) {
        self.pageSize = [BNHtmlPdfKit defaultPageSize];
        self.landscape = NO;
        
        CGFloat footerHeight = 60;
        self.contentInset = UIEdgeInsetsMake(0, 0, footerHeight, 0);
    }
    return self;
}

- (void)dealloc {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeout) object:nil];
    
    [self.webView setDelegate:nil];
    [self.webView stopLoading];
}

#pragma mark - Class Methods

+ (CGSize)sizeForPageSize:(BNPageSize)pageSize {
    switch (pageSize) {
        case BNPageSizeLetter:
            return BNSizeMakeWithPPI(8.5f, 11.0f);
        case BNPageSizeGovernmentLetter:
            return BNSizeMakeWithPPI(8.0f, 10.5f);
        case BNPageSizeLegal:
            return BNSizeMakeWithPPI(8.5f, 14.0f);
        case BNPageSizeJuniorLegal:
            return BNSizeMakeWithPPI(8.5f, 5.0f);
        case BNPageSizeLedger:
            return BNSizeMakeWithPPI(17.0f, 11.0f);
        case BNPageSizeTabloid:
            return BNSizeMakeWithPPI(11.0f, 17.0f);
        case BNPageSizeA0:
            return BNSizeMakeWithPPI(33.11f, 46.81f);
        case BNPageSizeA1:
            return BNSizeMakeWithPPI(23.39f, 33.11f);
        case BNPageSizeA2:
            return BNSizeMakeWithPPI(16.54f, 23.39f);
        case BNPageSizeA3:
            return BNSizeMakeWithPPI(11.69f, 16.54f);
        case BNPageSizeA4:
            return BNSizeMakeWithPPI(8.26666667, 11.6916667);
        case BNPageSizeA5:
            return BNSizeMakeWithPPI(5.83f, 8.27f);
        case BNPageSizeA6:
            return BNSizeMakeWithPPI(4.13f, 5.83f);
        case BNPageSizeA7:
            return BNSizeMakeWithPPI(2.91f, 4.13f);
        case BNPageSizeA8:
            return BNSizeMakeWithPPI(2.05f, 2.91f);
        case BNPageSizeA9:
            return BNSizeMakeWithPPI(1.46f, 2.05f);
        case BNPageSizeA10:
            return BNSizeMakeWithPPI(1.02f, 1.46f);
        case BNPageSizeB0:
            return BNSizeMakeWithPPI(39.37f, 55.67f);
        case BNPageSizeB1:
            return BNSizeMakeWithPPI(27.83f, 39.37f);
        case BNPageSizeB2:
            return BNSizeMakeWithPPI(19.69f, 27.83f);
        case BNPageSizeB3:
            return BNSizeMakeWithPPI(13.90f, 19.69f);
        case BNPageSizeB4:
            return BNSizeMakeWithPPI(9.84f, 13.90f);
        case BNPageSizeB5:
            return BNSizeMakeWithPPI(6.93f, 9.84f);
        case BNPageSizeB6:
            return BNSizeMakeWithPPI(4.92f, 6.93f);
        case BNPageSizeB7:
            return BNSizeMakeWithPPI(3.46f, 4.92f);
        case BNPageSizeB8:
            return BNSizeMakeWithPPI(2.44f, 3.46f);
        case BNPageSizeB9:
            return BNSizeMakeWithPPI(1.73f, 2.44f);
        case BNPageSizeB10:
            return BNSizeMakeWithPPI(1.22f, 1.73f);
        case BNPageSizeC0:
            return BNSizeMakeWithPPI(36.10f, 51.06f);
        case BNPageSizeC1:
            return BNSizeMakeWithPPI(25.51f, 36.10f);
        case BNPageSizeC2:
            return BNSizeMakeWithPPI(18.03f, 25.51f);
        case BNPageSizeC3:
            return BNSizeMakeWithPPI(12.76f, 18.03f);
        case BNPageSizeC4:
            return BNSizeMakeWithPPI(9.02f, 12.76f);
        case BNPageSizeC5:
            return BNSizeMakeWithPPI(6.38f, 9.02f);
        case BNPageSizeC6:
            return BNSizeMakeWithPPI(4.49f, 6.38f);
        case BNPageSizeC7:
            return BNSizeMakeWithPPI(3.19f, 4.49f);
        case BNPageSizeC8:
            return BNSizeMakeWithPPI(2.24f, 3.19f);
        case BNPageSizeC9:
            return BNSizeMakeWithPPI(1.57f, 2.24f);
        case BNPageSizeC10:
            return BNSizeMakeWithPPI(1.10f, 1.57f);
        case BNPageSizeJapaneseB0:
            return BNSizeMakeWithPPI(40.55f, 57.32f);
        case BNPageSizeJapaneseB1:
            return BNSizeMakeWithPPI(28.66f, 40.55f);
        case BNPageSizeJapaneseB2:
            return BNSizeMakeWithPPI(20.28f, 28.66f);
        case BNPageSizeJapaneseB3:
            return BNSizeMakeWithPPI(14.33f, 20.28f);
        case BNPageSizeJapaneseB4:
            return BNSizeMakeWithPPI(10.12f, 14.33f);
        case BNPageSizeJapaneseB5:
            return BNSizeMakeWithPPI(7.17f, 10.12f);
        case BNPageSizeJapaneseB6:
            return BNSizeMakeWithPPI(5.04f, 7.17f);
        case BNPageSizeJapaneseB7:
            return BNSizeMakeWithPPI(3.58f, 5.04f);
        case BNPageSizeJapaneseB8:
            return BNSizeMakeWithPPI(2.52f, 3.58f);
        case BNPageSizeJapaneseB9:
            return BNSizeMakeWithPPI(1.77f, 2.52f);
        case BNPageSizeJapaneseB10:
            return BNSizeMakeWithPPI(1.26f, 1.77f);
        case BNPageSizeJapaneseB11:
            return BNSizeMakeWithPPI(0.87f, 1.26f);
        case BNPageSizeJapaneseB12:
            return BNSizeMakeWithPPI(0.63f, 0.87f);
        case BNPageSizeCustom:
            return CGSizeZero;
    }
    return CGSizeZero;
}

- (NSURL *)baseUrl {
    if (!_baseUrl) {
        //_baseUrl = [NSURL URLWithString:@"http://localhost"];
        _baseUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    }
    return _baseUrl;
}

#pragma mark - Methods

- (CGSize)actualPageSize {
    if (self.landscape) {
        CGSize pageSize = [self _sizeFromPageSize:self.pageSize];
        return CGSizeMake(pageSize.height, pageSize.width);
    }
    return [self _sizeFromPageSize:self.pageSize];
}

- (void)saveHtmlAsPdf:(NSString *)html {
    [self saveHtmlAsPdf:html toFile:nil];
}

- (void)saveHtmlAsPdf:(NSString *)html pageHeader:(NSString *)pageHeader
           pageFooter:(NSString *)pageFooter toFile:(NSString *)file {
    
    CGFloat contentWidth = [self actualPageSize].width;
    if (pageHeader) {
        self.headerWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, contentWidth, 300)];
        self.headerWebView.delegate = self;
        self.headerWebView.tag = HeaderWebViewTag;
        [self.headerWebView loadHTMLString:pageHeader baseURL:self.baseUrl];
    }
    
    if (pageFooter) {
        self.footerWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, contentWidth, 300)];
        self.footerWebView.delegate = self;
        self.footerWebView.tag = FooterWebViewTag;
        [self.footerWebView loadHTMLString:pageFooter baseURL:self.baseUrl];
    }
    
    [self saveHtmlAsPdf:html toFile:file];
}

- (void)saveHtmlAsPdf:(NSString *)html toFile:(NSString *)file {
    self.outputFile = file;
    
    self.webView = [[UIWebView alloc] init];
    self.webView.scalesPageToFit = YES;
    self.webView.tag = ContentWebViewTag;
    self.webView.delegate = self;
    [self.webView loadHTMLString:html baseURL:self.baseUrl];
}

- (void)saveUrlAsPdf:(NSURL *)url {
    [self saveUrlAsPdf:url toFile:nil];
}

- (void)saveUrlAsPdf:(NSURL *)url toFile:(NSString *)file {
    self.outputFile = file;
    
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    if ([self.webView respondsToSelector:@selector(setSuppressesIncrementalRendering:)]) {
        [self.webView setSuppressesIncrementalRendering:YES];
    }
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)saveWebViewAsPdf:(UIWebView *)webView {
    [self saveWebViewAsPdf:webView toFile:nil];
}

- (void)saveWebViewAsPdf:(UIWebView *)webView toFile:(NSString *)file {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeout) object:nil];
    
    self.outputFile = file;
    
    webView.delegate = self;
    
    self.webView = webView;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    BOOL complete = [readyState isEqualToString:@"complete"];
    
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeout) object:nil];
    
    if (complete) {
        CGFloat htmlViewHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
        
        CGFloat top = self.contentInset.top;
        CGFloat left = self.contentInset.left;
        CGFloat right = self.contentInset.right;
        CGFloat bottom = self.contentInset.bottom;
        
        if (webView.tag == HeaderWebViewTag) {
            self.isHeaderFinishLoad = YES;
            self.contentInset = UIEdgeInsetsMake(htmlViewHeight, left, bottom, right);
        } else if (webView.tag == ContentWebViewTag) {
            self.isContentFinishLoad = YES;
        } else if (webView.tag == FooterWebViewTag) {
            self.isFooterFinishLoad = YES;
            self.contentInset = UIEdgeInsetsMake(top, left, htmlViewHeight, right);
        }
        
        if (self.headerWebView && self.isHeaderFinishLoad && self.isContentFinishLoad) {
            CGFloat top = self.contentInset.top;
            CGFloat bottom = self.contentInset.bottom;
            CGFloat contentHeight = [self actualPageSize].height - top -bottom;
            [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContentHeight('%f')", contentHeight]];
//            [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setContentHeight()"]];
            [self _savePdf];
        } else if (!self.headerWebView &&
            self.isContentFinishLoad) {
            [self _savePdf];
        }
    } else {
        [self performSelector:@selector(_timeout) withObject:nil afterDelay:1.0f];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_timeout) object:nil];
    
    if (self.failureBlock) {
        self.failureBlock(error);
    }
    
    if ([self.delegate respondsToSelector:@selector(htmlPdfKit:didFailWithError:)]) {
        [self.delegate htmlPdfKit:self didFailWithError:error];
    }
    
    self.webView = nil;
}

#pragma mark - Private Methods

- (void)_timeout {
    [self _savePdf];
}

- (void)_savePdf {
    if (!self.webView) {
        return;
    }
    CGSize pageSize = [self actualPageSize];
    CGRect pageRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
    
    UIPrintFormatter *formatter = self.webView.viewPrintFormatter;
    
    BNHtmlPdfKitPageRenderer *renderer = [[BNHtmlPdfKitPageRenderer alloc] init];
    renderer.contentInset = self.contentInset;
    
    if (self.headerWebView) {
        renderer.headerHeight = self.contentInset.top;
        renderer.footerHeight = self.contentInset.bottom;
        renderer.pageHeader = self.headerWebView;
    }
    
    if (self.footerWebView) {
        renderer.pageFooter = self.footerWebView;
    }
    
    [renderer addPrintFormatter:formatter startingAtPageAtIndex:0];
    
    NSMutableData *currentReportData = [NSMutableData data];
    
    UIGraphicsBeginPDFContextToData(currentReportData, pageRect, nil);
    
    [renderer prepareForDrawingPages:NSMakeRange(0, 1)];
    
    NSInteger pages = [renderer numberOfPages];
    
    for (NSInteger i = 0; i < pages; i++) {
        UIGraphicsBeginPDFPage();
        [renderer drawPageAtIndex:i inRect:renderer.paperRect];
    }
    
    UIGraphicsEndPDFContext();
    
    if (self.dataCompletionBlock) {
        self.dataCompletionBlock(currentReportData);
    }
    
    if (self.fileCompletionBlock) {
        self.fileCompletionBlock(self.outputFile);
    }
    
    if ([self.delegate respondsToSelector:@selector(htmlPdfKit:didSavePdfData:)]) {
        [self.delegate htmlPdfKit:self didSavePdfData:currentReportData];
    }
    
    if (self.outputFile) {
        [currentReportData writeToFile:self.outputFile atomically:YES];
        
        if ([self.delegate respondsToSelector:@selector(htmlPdfKit:didSavePdfFile:)]) {
            [self.delegate htmlPdfKit:self didSavePdfFile:self.outputFile];
        }
    }
    
    self.webView = nil;
}

- (CGSize)_sizeFromPageSize:(BNPageSize)pageSize {
    if (pageSize == BNPageSizeCustom) {
        return self.customPageSize;
    }
    
    return [BNHtmlPdfKit sizeForPageSize:pageSize];
}

+ (BNPageSize)defaultPageSize {
//    NSLocale *locale = [NSLocale currentLocale];
//    BOOL useMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
//    BNPageSize pageSize = (useMetric ? BNPageSizeA4 : BNPageSizeLetter);
//
//    return pageSize;
//    return BNPageSizeLetter;
    return BNPageSizeA4;
}

@end
