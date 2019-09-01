# FLAnimatedImageView+RGWrapper
This is a wrapper for FLAnimatedImageView

[FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) is a performant animated GIF engine for iOS

## What Dose This Wrapper Do?

- Your code could only use UIImageView and UIImage. 
- Don't need modify your ImageView class to display image

## Installation

To add it to your app, copy the three classes 

`FLAnimatedImage.h/.m`

`FLAnimatedImageView.h/.m`

`UIImageView+FLAnimatedImageView.h/.m`

into your Xcode project or add via [CocoaPods](http://cocoapods.org) by adding this to your Podfile:

```ruby
pod 'FLAnimatedImageView+RGWrapper'
```

## example

### load image from data

```objective-c
UIImageView *imageView = [UIImageView new];
UIImage *image = [UIImage rg_imageOrGifWithData:imageData];
imageView.image = image;
```
or

```objective-c
UIImageView *imageView = [UIImageView new];
// This method is thread-safe
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [imageView rg_setImageData:imageData delayPlayGif:1.f];
});
```


### load image from path for cell


```objective-c
NSString *path = self.imageData[indexPath.row];

// cancel last load task
[cell.imageView rg_cancelSetImagePath];

// load from path
// This method is thread-safe
[cell.imageView rg_setImagePath:path
                          async:YES
                   delayPlayGif:1.0
                   continueLoad:^BOOL(NSData * _Nonnull getData) {
                      // do some logic to judge need contine. 
                      // !!! notice⚠️ this block is not called in main thread.
                      <#code#>
                      return YES;
                   }];
```
