//
//  UIImageView+RGGif.m
//  CampTalk
//
//  Created by renge on 2019/8/3.
//  Copyright © 2019 yuru. All rights reserved.
//

#import "FLAnimatedImageView+RGWrapper.h"
#import "FLAnimatedImage/FLAnimatedImage.h"
#import <objc/runtime.h>

const char *animateViewKey = "gifView";
const char *RGImageViewLoadPath = "RGImageViewLoadPath";

@implementation UIImageView(FLAnimatedImageView)

- (dispatch_queue_t)loadDataQueue {
    static dispatch_queue_t _loadImageDataQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadImageDataQueue = dispatch_queue_create("_loadImageDataQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    return _loadImageDataQueue;
}

+ (void)__rg_swizzleOriginalSel:(SEL)originalSel swizzledSel:(SEL)swizzledSel {
    Class selfClass = [self class];
    Method originalMethod = class_getInstanceMethod(selfClass, originalSel);
    Method swizzledMethod = class_getInstanceMethod(selfClass, swizzledSel);
    
    BOOL didAddMethod =
    class_addMethod(selfClass,
                    originalSel,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(selfClass,
                            swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)load {
    [super load];
    [self __rg_swizzleOriginalSel:@selector(setContentMode:) swizzledSel:@selector(rg_setContentMode:)];
    [self __rg_swizzleOriginalSel:@selector(image) swizzledSel:@selector(rg_image)];
    [self __rg_swizzleOriginalSel:@selector(setImage:) swizzledSel:@selector(rg_setImage:)];
    
    SEL originalSel = @selector(initWithImage:);
    SEL swizzledSel = @selector(__rg_animatedViewInitWithImage:);

    Method originalMethod = class_getInstanceMethod(FLAnimatedImageView.class, originalSel);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSel);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

#pragma mark - Getter Setter

- (id)__rg_valueforConstKey:(const char *)key {
    return objc_getAssociatedObject(self, key);
}

- (void)__rg_setValue:(id)value forConstKey:(nonnull const char *)key retain:(BOOL)retain {
    objc_AssociationPolicy policy = retain ? OBJC_ASSOCIATION_RETAIN:OBJC_ASSOCIATION_ASSIGN;
    objc_setAssociatedObject(self, key, value, policy);
}

- (UIImage *)rg_image {
    if (self.rg_image) {
        return self.rg_image;
    }
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    if (gifView.animatedImage) {
        return [gifView.animatedImage imageLazilyCachedAtIndex:0];
    }
    return nil;
}

- (void)rg_setImage:(UIImage *)image {
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    if ([image isKindOfClass:UIImage.class]) {
        [self rg_setImage:image];
        gifView.animatedImage = nil;
        gifView.hidden = YES;
    } else if ([image isKindOfClass:FLAnimatedImage.class]) {
        [self rg_setImage:nil];
        self.gifView.animatedImage = (FLAnimatedImage *)image;
        gifView.hidden = NO;
    } else if ([image isKindOfClass:NSData.class]) {
        [self rg_setImageData:(NSData *)image];
    } else {
        if (self.image) {
            [self rg_setImage:nil];
        }
        if (gifView.animatedImage) {
            gifView.animatedImage = nil;
            gifView.hidden = YES;
        }
    }
}

- (void)rg_setContentMode:(UIViewContentMode)mode {
    [self rg_setContentMode:mode];
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    if (gifView.contentMode != mode) {
        gifView.contentMode = mode;
    }
}

- (void)rg_setPathId:(NSString *)path {
    [self __rg_setValue:path forConstKey:RGImageViewLoadPath retain:YES];
}

- (NSString *)rg_pathId {
    NSString *value = [self __rg_valueforConstKey:RGImageViewLoadPath];
    if (!value) {
        value = @"";
    }
    return value;
}

- (FLAnimatedImageView *)gifView {
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    if (!gifView) {
        gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        [self __rg_setValue:gifView forConstKey:animateViewKey retain:YES];
        gifView.contentMode = self.contentMode;
        gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:gifView atIndex:0];
    }
    return gifView;
}

- (instancetype)__rg_animatedViewInitWithImage:(UIImage *)image {
    id obj = [self __rg_animatedViewInitWithImage:image];
    if ([image isKindOfClass:FLAnimatedImage.class]) {
        [obj setAnimatedImage:(FLAnimatedImage *)image];
    }
    return obj;
}

#pragma mark - Public

- (void)rg_setImagePath:(NSString *)path async:(BOOL)async delayPlayGif:(NSTimeInterval)delayPlayGif continueLoad:(NS_NOESCAPE BOOL (^)(NSData * _Nonnull))continueLoad {
    [self rg_setImageUrl:[NSURL fileURLWithPath:path] async:async delayPlayGif:delayPlayGif continueLoad:continueLoad];
}

- (void)rg_setImageUrl:(NSURL *)url
                 async:(BOOL)async
          delayPlayGif:(NSTimeInterval)delayGif
          continueLoad:(NS_NOESCAPE BOOL (^)(NSData * _Nonnull))continueLoad {
    if (async) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.rg_pathId isEqualToString:url.absoluteString]) {
                return;
            }
            self.image = nil;
            [self rg_setPathId:url.absoluteString];
            
            dispatch_async(self.loadDataQueue, ^{
                NSData *data = [NSData dataWithContentsOfURL:url];
                if (!continueLoad || (continueLoad && continueLoad(data))) {
                    dispatch_async(self.loadDataQueue, ^{
                        [self rg_setImageData:data delayPlayGif:delayGif];
                    });
                }
            });
        });
    } else {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (continueLoad) {
            if (continueLoad(data)) {
                [self rg_setImageData:data delayPlayGif:delayGif];
            }
        } else {
            [self rg_setImageData:data delayPlayGif:delayGif];
        }
    }
}

- (void)rg_cancelSetImagePath {
    [self rg_setPathId:nil];
}

- (void)rg_setImagePath:(NSString *)path {
    [self rg_setImagePath:path async:NO delayPlayGif:0 continueLoad:nil];
}

- (void)rg_setImageData:(NSData *)data {
    [self rg_setImageData:data delayPlayGif:0];
}

- (void)rg_setImageData:(NSData *)data delayPlayGif:(NSTimeInterval)delayGif {
    
    __block NSString *path = [self rg_pathId];
    
    FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
    UIImage *firstImage = nil;
    if (image && delayGif) {
        firstImage = [image imageLazilyCachedAtIndex:0];
    }
    
    if (!image) {
        image = (FLAnimatedImage *)[UIImage imageWithData:data];
    }
    
    BOOL isMainThread = [NSThread isMainThread];
    
    void(^setImage)(void) = ^{
        if (delayGif && firstImage) {
            self.image = firstImage;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayGif * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (firstImage != self.image) {
                    return;
                }
                if (![path isEqualToString:self.rg_pathId]) {
                    return;
                }
                self.image = (UIImage *)image;
            });
        } else {
            self.image = (UIImage *)image;
        }
    };
    
    if (isMainThread) {
        if (!path.length) {
            NSUInteger hash = [data hash];
            path = @(hash).stringValue;
            [self rg_setPathId:path];
        }
        setImage();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (![path isEqualToString:self.rg_pathId]) {
                return;
            }
            if (!path.length) {
                NSUInteger hash = [data hash];
                path = @(hash).stringValue;
                [self rg_setPathId:path];
            }
            setImage();
        });
    }
}

- (BOOL)rg_isAnimating {
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    return gifView.isAnimating;
}

- (void)rg_stop {
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    [gifView stopAnimating];
}

- (void)rg_start {
    FLAnimatedImageView *gifView = [self __rg_valueforConstKey:animateViewKey];
    [gifView startAnimating];
}

@end


@implementation UIImage (FLAnimatedImage)

+ (UIImage *)rg_imageOrGifWithData:(NSData *)data {
    FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
    if (image) {
        return (UIImage *)image;
    }
    return [UIImage imageWithData:data];
}

@end


