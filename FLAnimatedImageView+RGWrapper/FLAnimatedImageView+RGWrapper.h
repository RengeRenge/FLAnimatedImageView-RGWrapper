//
//  UIImageView+RGGif.h
//  CampTalk
//
//  Created by renge on 2019/8/3.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for FLAnimatedImageView_RGWrapper.
FOUNDATION_EXPORT double FLAnimatedImageView_RGWrapperVersionNumber;

//! Project version string for FLAnimatedImageView_RGWrapper.
FOUNDATION_EXPORT const unsigned char FLAnimatedImageView_RGWrapperVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <FLAnimatedImageView_RGWrapper/PublicHeader.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView(FLAnimatedImageView)

- (void)rg_setImagePath:(NSString *)path;

- (void)rg_setImagePath:(NSString *)path
                  async:(BOOL)async
           delayPlayGif:(NSTimeInterval)delayPlayGif
           continueLoad:(NS_NOESCAPE BOOL(^_Nullable)(NSData *getData))continueLoad;

- (void)rg_setImageUrl:(NSURL *)url
                 async:(BOOL)async
          delayPlayGif:(NSTimeInterval)delayGif
          continueLoad:(NS_NOESCAPE BOOL (^)(NSData * _Nonnull))continueLoad;

- (void)rg_cancelSetImagePath;

- (void)rg_setImageData:(NSData *)data;
- (void)rg_setImageData:(NSData *)data delayPlayGif:(NSTimeInterval)delayPlayGif;

- (BOOL)rg_isAnimating;
- (void)rg_start;
- (void)rg_stop;

@end

@interface UIImage (FLAnimatedImage)

+ (UIImage *)rg_imageOrGifWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
