//
//  BNHtmlPdfKit.h
//
//  Created by Brent Nycum.
//  Copyright (c) 2013 Brent Nycum. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BNHtmlPdfKitDelegate;

// http://en.wikipedia.org/wiki/Paper_size
typedef enum {
    BNPageSizeLetter,
    BNPageSizeGovernmentLetter,
    BNPageSizeLegal,
    BNPageSizeJuniorLegal,
    BNPageSizeLedger,
    BNPageSizeTabloid,
    BNPageSizeA0,
    BNPageSizeA1,
    BNPageSizeA2,
    BNPageSizeA3,
    BNPageSizeA4,
    BNPageSizeA5,
    BNPageSizeA6,
    BNPageSizeA7,
    BNPageSizeA8,
    BNPageSizeA9,
    BNPageSizeA10,
    BNPageSizeB0,
    BNPageSizeB1,
    BNPageSizeB2,
    BNPageSizeB3,
    BNPageSizeB4,
    BNPageSizeB5,
    BNPageSizeB6,
    BNPageSizeB7,
    BNPageSizeB8,
    BNPageSizeB9,
    BNPageSizeB10,
    BNPageSizeC0,
    BNPageSizeC1,
    BNPageSizeC2,
    BNPageSizeC3,
    BNPageSizeC4,
    BNPageSizeC5,
    BNPageSizeC6,
    BNPageSizeC7,
    BNPageSizeC8,
    BNPageSizeC9,
    BNPageSizeC10,
    BNPageSizeJapaneseB0,
    BNPageSizeJapaneseB1,
    BNPageSizeJapaneseB2,
    BNPageSizeJapaneseB3,
    BNPageSizeJapaneseB4,
    BNPageSizeJapaneseB5,
    BNPageSizeJapaneseB6,
    BNPageSizeJapaneseB7,
    BNPageSizeJapaneseB8,
    BNPageSizeJapaneseB9,
    BNPageSizeJapaneseB10,
    BNPageSizeJapaneseB11,
    BNPageSizeJapaneseB12,
    BNPageSizeCustom
} BNPageSize;

@interface Foo : NSObject

@property(nonatomic, strong) NSString *bar;

@end

@interface BNHtmlPdfKit : NSObject

/**
 The paper size of the generated PDF.
 */
@property (nonatomic, assign) BNPageSize pageSize;

/**
 Custom page size.
 */
@property (nonatomic, assign) CGSize customPageSize;

/**
 Is page landscape?
 */
@property (nonatomic, assign, getter=isLandscape) BOOL landscape;

/**
 Page content margins.
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 Base URL to use.
 */
@property (nonatomic, retain) NSURL *baseUrl;

/**
 The receiver's `delegate`.
 
 The `delegate` is sent messages when content is loading.
 */
@property (nonatomic, assign) id<BNHtmlPdfKitDelegate> delegate;

/**
 Creates a BNHtmlPdfKit object to save a URL as PDF with BNPageSize.
 
 @param url URL to save PDF of.
 @param filename Filename to save file as.
 @param pageSize CGSize of the page to be generated.
 @param topAndBottom Top and bottom margin size.
 @param leftAndRight Left and right margin size.
 @param completion Block to be notified when PDF file is generated.
 @param failure Block to be notified of failure.
 */
+ (BNHtmlPdfKit *)saveHtmlAsPdf:(NSString *)contentHtml
                        toFile:(NSString *)filename
                pageHeaderHtml:(NSString *)headerHtml
                pageFooterHtml:(NSString *)footerHtml
                       success:(void (^)(NSString *filename))completion
                       failure:(void (^)(NSError *error))failure;

/**
 Get a CGSize of what the BNPageSize represents.
 
 @param pageSize Page Size to get the CGSize of.
 */
+ (CGSize)sizeForPageSize:(BNPageSize)pageSize;

/**
 The size of the paper to print on.
 */
- (CGSize)actualPageSize;

/**
 Determine the preferred paper size for general printing. From Pierre Bernard.
 
 @return paper size (currently: A4 or Letter).
 */
+ (BNPageSize)defaultPageSize;

@end;


/**
 The `BNHtmlPdfKitDelegate` protocol defines methods that a delegate of a `BNHtmlPdfKit` object that provides feedback
 based on the operations being performed.
 */
@protocol BNHtmlPdfKitDelegate <NSObject>

@optional

/**
 Sent when pdf data has been generated.
 
 @param htmlPdfKit The `BNHtmlPdfKit` that data is being saved from.
 @param data The PDF data that was created from HTML/URL.
 */
- (void)htmlPdfKit:(BNHtmlPdfKit *)htmlPdfKit didSavePdfData:(NSData *)data;

/**
 Sent when pdf data has been generated.
 
 @param htmlPdfKit The `BNHtmlPdfKit` that data is being saved from.
 @param data The PDF data that was created from HTML/URL.
 */
- (void)htmlPdfKit:(BNHtmlPdfKit *)htmlPdfKit didSavePdfFile:(NSString *)file;

/**
 Sent when there was an error trying to generate the PDF.
 
 @param htmlPdfKit The `BNHtmlPdfKit` that theerror generated from.
 */
- (void)htmlPdfKit:(BNHtmlPdfKit *)htmlPdfKit didFailWithError:(NSError *)error;

@end;
