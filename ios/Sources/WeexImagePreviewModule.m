//
//  WeexImagePreviewModule.m
//  WeexPlguinDemo
//
//  Created by Andy on 12/07/2017.
//  Copyright © 2017 weexplugin. All rights reserved.
//

#import "WeexImagePreviewModule.h"
#import "WeexImagePreviewLongPress.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <SDWebImageManager.h>

@interface WeexImagePreviewModule () <UIScrollViewDelegate>

// 要显示大图预览的 UIView。
@property (nonatomic, strong) UIView * targetView;
// 长按保存图片。
@property (nonatomic, strong) WeexImagePreviewLongPress * longPressImageHandler;
// 图片的 URL 数组。
@property (nonatomic, strong) NSMutableArray * imageURLArray;
// 图片数组。
@property (nonatomic, strong) NSMutableArray * imageArray;
// 大图预览的视图。
@property (nonatomic, strong) UIView * previewView;
// 预览内容的视图。
@property (nonatomic, strong) UIScrollView * contentView;
// 分页器。
@property (nonatomic, strong) UIPageControl * pageControl;
// 加载框的 UI 数组。
@property (nonatomic, strong) NSMutableArray * activityLoadingBoxArray;
// 图片的请求队列。
@property (nonatomic, strong) NSOperationQueue * requestQueue;

@end

@implementation WeexImagePreviewModule

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(weexImagePreview, WeexImagePreviewModule)
WX_EXPORT_METHOD(@selector(show:))

/**
 show image preview
 
 @param params images and index
 */
-(void)show:(NSDictionary *)params
{
    //WV_JSB_CHECK_PARAMS_RETURN();
    
    NSArray * images = [params valueForKey:@"images"];
//    if (!images || images.count <= 0) {
//        WV_JSB_CALLBACK_PARAM_ERR_RETURN(@"No images.");
//    }
//    
    NSInteger index = [[params valueForKey:@"index"] integerValue];
    if (index < 0) {
        index = 0;
    } else if (index >= images.count) {
        index = images.count - 1;
    }
    
    [self showImagePreviewWidget:images withIndex:index toSourceView:weexInstance.viewController.view.window];
//    WV_JSB_CALLBACK(callback, MSG_RET_SUCCESS, nil);
}

#pragma mark - Create UI

/**
 * 显示横向大图预览。
 */
- (void)showImagePreviewWidget:(NSArray *)images withIndex:(NSInteger)index toSourceView:(UIView *)sourceView {
    _targetView = sourceView;
    _imageURLArray = [images mutableCopy];
    NSUInteger cnt = _imageURLArray.count;
    _imageArray = [NSMutableArray arrayWithCapacity:cnt];
    for (NSInteger i = 0; i < cnt; i++) {
        [_imageArray addObject:NSNull.null];
    }
    
    [self initPreviewView];
    [self initContentView];
    [self initPageControlWithIndex:index];
    
    // 加载框的 UI 数组。
    if (!_activityLoadingBoxArray) {
        _activityLoadingBoxArray = [[NSMutableArray alloc] initWithCapacity:cnt];
    }
    
    // 请求队列，最多并发 3 个。
    if (!_requestQueue) {
        _requestQueue = [[NSOperationQueue alloc] init];
        [_requestQueue setMaxConcurrentOperationCount:3];
    }
    
    CGRect frame = _targetView.bounds;
    for (NSInteger i = 0; i < cnt; i++) {
        UIActivityIndicatorView * loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        // 30x30，居中
        loadingView.frame = CGRectMake(i * frame.size.width + (frame.size.width - 30) / 2, (frame.size.height - 30) / 2, 30, 30);
        [loadingView startAnimating];
        
        [_contentView addSubview:loadingView];
        [_activityLoadingBoxArray addObject:loadingView];
        
        if (index == i) {
            [self lazyLoadImageWithIndex:i];
        }
    }
    
    // 使用过渡动画显示界面。
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         _previewView.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                     }];
}

/**
 * 初始化大图预览视图。
 */
- (void)initPreviewView {
    CGRect frame = _targetView.bounds;
    
    if (!_previewView) {
        _previewView = [[UIView alloc] initWithFrame:frame];
        _previewView.alpha = 0.0f;
        // 添加背景。
        UIView * backgroundView = [[UIView alloc] initWithFrame:frame];
        [backgroundView setBackgroundColor:[UIColor darkTextColor]];
        [_previewView addSubview:backgroundView];
        
        // 长按保存图片。
        _longPressImageHandler = [[WeexImagePreviewLongPress alloc] init];
        __block __weak typeof(self) weak = self;
        _longPressImageHandler.imageOfLocation = ^UIImage *(CGPoint location) {
            UIImage * image = weak.imageArray[[weak currentPageIndex]];
            if (image && [image isKindOfClass:[UIImage class]]) {
                return image;
            } else {
                return nil;
            }
        };
        [_longPressImageHandler bind:_previewView];
    }
    
    [_previewView removeFromSuperview];
    [_targetView addSubview:_previewView];
}

/**
 * 初始化内容视图。
 */
- (void)initContentView {
    // 创建内容视图。
    if (!_contentView) {
        CGRect frame = _targetView.bounds;
        _contentView = [[UIScrollView alloc] initWithFrame:frame];
        [_contentView setPagingEnabled:YES];
        [_contentView setUserInteractionEnabled:YES];
        [_contentView setBounces:YES];
        [_contentView setShowsHorizontalScrollIndicator:NO];
        [_contentView setShowsVerticalScrollIndicator:NO];
        [_contentView setContentSize:CGSizeMake(frame.size.width * _imageURLArray.count, frame.size.height)];
        [_contentView setScrollsToTop:NO];
        [_contentView setDelegate:self];
        [self bindTapGestureViewAction:_contentView];
        
        [_previewView addSubview:_contentView];
    }
}

/**
 * 绑定点击手势。
 */
- (void)bindTapGestureViewAction:(UIScrollView *)scrollView {
    UITapGestureRecognizer * doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomInImage:)];
    [doubleTap setNumberOfTapsRequired:2];
    [doubleTap setNumberOfTouchesRequired:1];
    
    [scrollView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideImagePreview:)];
    [tap setNumberOfTapsRequired:1];
    [tap setNumberOfTouchesRequired:1];
    [tap requireGestureRecognizerToFail:doubleTap];
    
    [scrollView addGestureRecognizer:tap];
}

/**
 * 初始化分页器。
 */
- (void)initPageControlWithIndex:(NSUInteger)index {
    // 至多显示 9 张图片的分页器。
    if (!_pageControl && [_imageURLArray count] > 1 && [_imageURLArray count] < 10) {
        CGRect frame = _targetView.bounds;
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, frame.size.height - 80, frame.size.width, 30)];
        
        [_pageControl setNumberOfPages:[_imageURLArray count]];
        [_pageControl setCurrentPage:index];
        [_pageControl addTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
        
        [_previewView addSubview:_pageControl];
    }
    // 初始跳转到指定页。
    [self pageTurn:index animated:NO];
}

#pragma mark - Load Image

/**
 * 懒加载指定索引的图片。
 */
- (void)lazyLoadImageWithIndex:(NSInteger)index {
    
    if (index < 0 || index >= _imageURLArray.count) {
        return;
    }
    
    NSString * imageURL = _imageURLArray[index];
    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:imageURL]
                                                    options:0
                                                   progress:nil
                                                  completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
    {
        if (finished && error == nil) {
            [self addImage:image withIndex:index];
        }
    }];
    
    // 将 URL 标记为空。
//    _imageURLArray[index] = @"";
}

/**
 * 向指定索引添加图片。
 */
- (void)addImage:(UIImage *)image withIndex:(NSInteger)index {
    // 必须在主线程操作。
    if (![NSThread isMainThread]) {
        __block __weak typeof(self) weak = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weak addImage:image withIndex:index];
        });
        return;
    }
    
    if (!image) {
        return;
    }
    
    _imageArray[index] = image;
    // 创建图片 ImageView。
    UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
    
    CGSize frameSize = _previewView.bounds.size;
    // 图片等比缩放，适合界面。
    float imageWidth = frameSize.width;
    float imageHeight = imageView.frame.size.height / imageView.frame.size.width * imageWidth;
    imageView.frame = CGRectMake(0, 0, imageWidth, imageHeight);
    imageView.userInteractionEnabled = YES;
    
    // 图片太大，要上下滑动。
    UIScrollView * imageScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(index * frameSize.width, 0, frameSize.width, frameSize.height)];
    [imageScroll setContentSize:imageView.frame.size];
    
    [imageScroll setMinimumZoomScale:1.0];
    [imageScroll setMaximumZoomScale:4.0];
    [imageScroll setBouncesZoom:YES];
    [imageScroll setDelegate:self];
    [imageScroll setUserInteractionEnabled:YES];
    [imageScroll setBounces:NO];
    [imageScroll setPagingEnabled:NO];
    [imageScroll setShowsHorizontalScrollIndicator:NO];
    [imageScroll setShowsVerticalScrollIndicator:NO];
    [imageScroll setBackgroundColor:[UIColor clearColor]];
    [imageScroll addSubview:imageView];
    [imageScroll setScrollsToTop:YES];
    [imageScroll setAlpha:0.0f];
    [imageScroll setTag:index];
    
    // 令图片垂直居中。
    if (imageHeight <= frameSize.height) {
        [self scrollViewDidZoom:imageScroll];
    }
    
    [_contentView addSubview:imageScroll];
    
    [UIView animateWithDuration:0.2f
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         [imageScroll setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                     }];
    
    [self hiddenActivityWithIndex:index];
}

/**
 * 隐藏指定索引的菊花。
 */
- (void)hiddenActivityWithIndex:(NSInteger)index {
    if (index < [_activityLoadingBoxArray count]) {
        UIActivityIndicatorView * act = _activityLoadingBoxArray[index];
        [act stopAnimating];
        [act removeFromSuperview];
    }
}

#pragma mark - Tap Gesture

/**
 * 放大当前图片。
 */
- (void)zoomInImage:(UITapGestureRecognizer *)gesture {
    UIScrollView * currentView = [self subViewInIndex:[self currentPageIndex]];
    if (!currentView) {
        return;
    }
    
    UIImageView * imageView = (UIImageView *)[self viewForZoomingInScrollView:currentView];
    
    float currentScale = [currentView zoomScale];
    // 每次放大两倍。
    float newScale = currentScale * 2;
    
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gesture locationInView:currentView] withScrollView:currentView withImageView:imageView];
    [currentView zoomToRect:zoomRect animated:YES];
}

/**
 * 返回指定索引的滚动视图。
 */
- (UIScrollView *)subViewInIndex:(NSInteger)index {
    NSArray * subViews = _contentView.subviews;
    if (subViews) {
        for (NSUInteger i = 0; i < subViews.count; i++) {
            UIScrollView * v = subViews[i];
            if ([v isKindOfClass:[UIScrollView class]] && v.tag == index) {
                return v;
            }
        }
    }
    
    return nil;
}

/**
 * 返回缩放矩形。
 */
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center withScrollView:(UIScrollView *)scrollView withImageView:(UIImageView *)imageView {
    
    CGRect zoomRect;
    
    CGSize frameSize = scrollView.frame.size;
    zoomRect.size.height = frameSize.height / scale;
    zoomRect.size.width = frameSize.width / scale;
    zoomRect.origin.x = center.x / scale * 2 - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y / scale * 2 - (zoomRect.size.height / 2.0);
    
    if (imageView) {
        zoomRect.origin.y += imageView.frame.origin.y;
    }
    
    return zoomRect;
}

/**
 * 隐藏图片预览。
 */
- (void)hideImagePreview:(UITapGestureRecognizer *)tapGesture {
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         _previewView.alpha = 0.1f;
                     }
                     completion:^(BOOL finished) {
                         [self releaseInstance];
                     }];
}

/**
 * 当前的页面索引。
 */
- (NSInteger)currentPageIndex {
    // 不能使用 pageControl，因为可能不存在。
    return _contentView.contentOffset.x / _contentView.frame.size.width;
}

#pragma mark - UIScrollViewDelegate

/**
 * 返回指定滚动视图中的视图。
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    NSArray * subViews = scrollView.subviews;
    if (subViews) {
        for (UIView * v in subViews) {
            if ([v isKindOfClass:[UIImageView class]]) {
                return v;
            }
        }
    }
    
    return nil;
}

/**
 * 结束滚动。
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == _contentView) {
        // 仅切换图片时才设置 pageControl。
        NSInteger currentPage = [self currentPageIndex];
        
        if (_pageControl && _pageControl.currentPage != currentPage) {
            [_pageControl setCurrentPage:currentPage];
        }
        [self lazyLoadImageWithIndex:currentPage];
    }
}

/**
 * 结束滚动。
 */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}

/**
 * 结束缩放。
 */
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale animated:NO];
}

/**
 * 缩放比例被改变。
 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = 0.0, offsetY = 0.0;
    CGSize frameSize = scrollView.bounds.size;
    CGSize contentSize = scrollView.contentSize;
    if (frameSize.width > contentSize.width) {
        offsetX = (frameSize.width - contentSize.width) * 0.5;
    }
    if (frameSize.height > contentSize.height) {
        offsetY = (frameSize.height - contentSize.height) * 0.5;
    }
    
    UIImageView * imageView = (UIImageView *)[self viewForZoomingInScrollView:scrollView];
    if (imageView) {
        imageView.center = CGPointMake(contentSize.width * 0.5 + offsetX, contentSize.height * 0.5 + offsetY);
    }
}

/**
 * 跳转到指定页面。
 */
- (void)pageTurn:(UIPageControl *)sender {
    [self pageTurn:sender.currentPage animated:YES];
}

/**
 * 跳转到指定页面。
 */
- (void)pageTurn:(NSInteger)index animated:(BOOL)animated {
    CGSize viewSize = _previewView.bounds.size;
    CGRect rect = CGRectMake(index * viewSize.width, 0, viewSize.width, viewSize.height);
    [_contentView scrollRectToVisible:rect animated:animated];
}

#pragma mark - Release

- (void)releaseInstance {
//    [super releaseInstance];
    [self removeImagePreviewWidget];
}

- (void)dealloc {
    [self removeImagePreviewWidget];
}

- (void)removeImagePreviewWidget {
    if (_contentView) {
        [_contentView removeFromSuperview];
        _contentView.delegate = nil;
        _contentView = nil;
    }
    
    if (_pageControl) {
        [_pageControl removeFromSuperview];
        [_pageControl removeTarget:self action:@selector(pageTurn:) forControlEvents:UIControlEventValueChanged];
        _pageControl = nil;
    }
    
    if (_requestQueue) {
        [_requestQueue cancelAllOperations];
        _requestQueue = nil;
    }
    
    if (_activityLoadingBoxArray) {
        for (UIActivityIndicatorView * v in _activityLoadingBoxArray) {
            [v stopAnimating];
            [v removeFromSuperview];
        }
    }
    
    if (_previewView) {
        [_previewView removeFromSuperview];
        _previewView = nil;
    }
}

@end
