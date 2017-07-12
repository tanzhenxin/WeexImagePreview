//
//  WeexImagePreviewLongPress.m
//  WeexPlguinDemo
//
//  Created by Andy on 12/07/2017.
//  Copyright © 2017 weexplugin. All rights reserved.
//

#import "WeexImagePreviewLongPress.h"
#import <MBProgressHUD.h>

@interface WeexImagePreviewLongPress () <UIGestureRecognizerDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) UIImage * image;

// 绑定到的视图。
@property (nonatomic, weak, readonly) UIView *view;
// 手势识别。
@property (nonatomic, strong) UILongPressGestureRecognizer * gesture;
// 是否已绑定。
@property (nonatomic, assign) BOOL isBound;
// 询问视图。
@property (nonatomic, strong) UIActionSheet * askSheet;

@end

@implementation WeexImagePreviewLongPress

/**
 * 绑定指定视图。
 *
 * @param view 要绑定的视图。
 */
- (void)bind:(UIView *)view {
    if (_isBound) {
        if (view == _view) {
            return;
        } else {
            [self unbind];
        }
    }
    _view = view;
    _isBound = YES;
    
    if (!_gesture) {
        _gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSeclector:)];
        _gesture.delegate = self;
        _gesture.numberOfTapsRequired = 0;
        _gesture.numberOfTouchesRequired = 1;
        _gesture.minimumPressDuration = 0.7f;
        _gesture.allowableMovement = 0.0f;
        _gesture.cancelsTouchesInView = NO;
    }
    
    [_view addGestureRecognizer:_gesture];
}

/**
 * 解绑视图。
 */
- (void)unbind {
    if (!_isBound) {
        return;
    }
    _isBound = NO;
    if (_gesture) {
        [_view removeGestureRecognizer:_gesture];
    }
}

- (void)dealloc {
    [self unbind];
}

#pragma mark- UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return _isBound;
}

/**
 * 触发长按事件。
 */
- (void)longPressSeclector:(UILongPressGestureRecognizer *)sender {
    if (!_isBound || sender.state != UIGestureRecognizerStateBegan){
        return;
    }
    
    if (!_askSheet) {
        _askSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"保存图片?",)
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"取消",)
                                  destructiveButtonTitle:NSLocalizedString(@"保存",)
                                       otherButtonTitles:nil];
    }
    
    __block __weak typeof(self) weak = self;
    [self fetchImage:[sender locationInView:_view] callback:^{
        [weak.askSheet showInView:weak.view.window];
    }];
}

#pragma mark- UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([NSLocalizedString(@"保存",) isEqualToString:[actionSheet buttonTitleAtIndex:buttonIndex]]) {
        [self saveImage];
    }
}

#pragma mark- Image

/**
 * 保存图片到相册。
 *
 * @param image 要保存的图片。
 */
- (void)saveImageToAlbum:(UIImage *)image {
    if (image) {
        @try {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        } @catch (NSException * exception) {
        }
    } else {
        [self image:nil didFinishSavingWithError:nil contextInfo:nil];
    }
}

/**
 * 图片保存完毕。
 */
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString * msg;
    if (error || !image) {
        msg = NSLocalizedString(@"图片保存失败",);
    } else {
        msg = NSLocalizedString(@"图片保存成功",);
    }
    MBProgressHUD *toast = [MBProgressHUD showHUDAddedTo:self.view animated:TRUE];
    toast.mode = MBProgressHUDModeText;
    toast.labelText = msg;
    [toast hideAnimated:TRUE afterDelay:0.8];
}

/**
 * 提取图片。
 *
 * @param locationInView 长按的视图位置。
 * @param callback       图片提取成功的回调。
 */
- (void)fetchImage:(CGPoint)locationInView callback:(void (^)(void))callback {
    if (!_imageOfLocation) {
        return;
    }
    
    _image = _imageOfLocation(locationInView);
    if (_image) {
        callback();
    }
}

/**
 * 保存图片。
 * 供子类重写使用。
 */
- (void)saveImage {
    if (_image) {
        [self saveImageToAlbum:_image];
    }
}


@end
