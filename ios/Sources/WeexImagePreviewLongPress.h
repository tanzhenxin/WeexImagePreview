//
//  WeexImagePreviewLongPress.h
//  WeexPlguinDemo
//
//  Created by Andy on 12/07/2017.
//  Copyright © 2017 weexplugin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WeexImagePreviewLongPress : NSObject

/**
 * 返回指定位置的图片。
 */
@property (nonatomic, copy) UIImage * (^imageOfLocation)(CGPoint location);

/**
 * 绑定指定视图。
 *
 * @param view 要绑定的视图。
 */
- (void)bind:(UIView *)view;

/**
 * 解绑视图。
 */
- (void)unbind;


@end
