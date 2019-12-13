//
//  UIScrollView+XPRefresher.h
//  Brook
//
//  Created by Brook on 2017/5/23.
//  Copyright © 2017年 Brook. All rights reserved.
//  处理 scrollView 的下拉刷新/上拉加载更多

#import <UIKit/UIKit.h>
#import "XPRefresher.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (XPRefresher)

/// 配置 scrollView 的下拉/上拉事件，注意循环引用，刷新请求完成时需要手动调用，下面的 xp_endWithSucceed:hasMore: 方法
- (void)xp_configRefreshCanRefresh:(BOOL)canRefresh canLoadMore:(BOOL)canLoadMore callback:(XPRefresherCallback)callback;

/// 强制重新请求刷新列表，等价于调用 .xp_refresher 的 startRefreshingAnimated:
- (void)xp_startRefreshingAnimated:(BOOL)animated;
- (void)xp_startLoadingMoreAnimated:(BOOL)animated;

/// 结束刷新/下拉请求后的 UI 处理
- (void)xp_endRefresherWithSucceed:(BOOL)succeed hasMore:(NSNull *_Nullable)hasMore;

/// 管理上下拉刷新的对象，访问此属性之前，需要先调用 xp_config 方法
@property (nonatomic, strong, null_resettable, readonly) XPRefresher *xp_refresher;

@end

@interface UIScrollView (XPRefresherNotRecommanded)

/// 配置 scrollView 的下拉/上拉事件，回调时携带一个 completion block 可以在刷新请求完成时调用，注意循环引用
- (void)xp_configRefreshCanRefresh:(BOOL)canRefresh canLoadMore:(BOOL)canLoadMore handler:(XPRefreshHandler)handler;

@end

NS_ASSUME_NONNULL_END
