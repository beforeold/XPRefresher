//
//  XPRefresher.h
//  Brook
//
//  Created by Brook on 2017/5/25.
//  Copyright © 2017年 Brook. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 描述当前刷新事件的状态
typedef struct XPRefreshingContext {
    /*是否为下拉刷新*/
    BOOL isRefresh;
    
    /*是否触发了下拉刷新的动画*/
    BOOL isAnimated;
    
    /*当前页数*/
    NSInteger page;
} XPRefreshingContext;

NS_ASSUME_NONNULL_BEGIN


typedef NSNull* XPHasMore;

FOUNDATION_STATIC_INLINE XPHasMore _Nullable XPHasMoreMakeWithBool(BOOL hasMore) {
    return hasMore ? NSNull.null : nil;
}

FOUNDATION_STATIC_INLINE BOOL XPRefresingContextNeedHUD(XPRefreshingContext context) {
    return context.isRefresh && !context.isAnimated;
}

/// 处理刷新操作请求结束后的回执
typedef void(^XPRequestEndCompletion)(BOOL succeed, XPHasMore _Nullable hasMore);

/// 下拉或上拉事件的回调，携带一个 block 参数用于结束刷新动作
typedef void(^XPRefreshHandler)(XPRefreshingContext context, XPRequestEndCompletion completion);

/// 下拉或上拉事件的回调，需要手动结束刷新动作
typedef void(^XPRefresherCallback)(XPRefreshingContext context);

@interface XPRefresher : NSObject

- (instancetype)initWithScrollView:(UIScrollView *)scrollView canRefresh:(BOOL)canRefresh canLoadMore:(BOOL)canLoadMore;

/// 从 1 开始计算 page
@property (nonatomic, assign, readonly) NSInteger page;

/// 添加更多回调的接收者
- (void)_addHandler:(XPRefreshHandler)handler;

- (void)addCallback:(XPRefresherCallback)callback;

/// 强制调用刷新操作，如果 animated 则会出现下拉动画
- (void)startRefreshingAnimated:(BOOL)animated;

/// 强制调用刷新操作，如果 animated 则会出现下拉动画
- (void)startLoadingMoreAnimated:(BOOL)animated;

/// 结束刷新/下拉请求后的 UI 处理
- (void)endWithSucceed:(BOOL)succeed hasMore:(NSNull *_Nullable)hasMore;

@end

@interface XPRefresher (XPCustomSetting)

@property (nonatomic, strong, readonly, nullable) MJRefreshHeader *header;
@property (nonatomic, strong, readonly, nullable) MJRefreshAutoNormalFooter *footer;

@end


NS_ASSUME_NONNULL_END
