//
//  UIScrollView+XPRefresher.m
//  Brook
//
//  Created by Brook on 2017/5/23.
//  Copyright © 2017年 Brook. All rights reserved.
//

#import "UIScrollView+XPRefresher.h"
#import <objc/runtime.h>

@interface UIScrollView ()

@property (nonatomic, strong, readwrite) XPRefresher *xp_refresher;

@end

@implementation UIScrollView (XPRefresher)

- (void)xp_configRefreshCanRefresh:(BOOL)canRefresh canLoadMore:(BOOL)canLoadMore callback:(XPRefresherCallback)callback {
    self.xp_refresher = [[XPRefresher alloc] initWithScrollView:self canRefresh:canRefresh canLoadMore:canLoadMore];
    [self.xp_refresher addCallback:callback];
}

- (void)setXp_refresher:(XPRefresher *)refresher {
    objc_setAssociatedObject(self, @selector(xp_refresher), refresher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (XPRefresher *)xp_refresher {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)xp_startRefreshingAnimated:(BOOL)animated {
    [self.xp_refresher startRefreshingAnimated:animated];
}

- (void)xp_startLoadingMoreAnimated:(BOOL)animated {
    [self.xp_refresher startLoadingMoreAnimated:animated];
}

- (void)xp_endRefresherWithSucceed:(BOOL)succeed hasMore:(NSNull *_Nullable)hasMore {
    [self.xp_refresher endWithSucceed:succeed hasMore:hasMore];
}

@end

@implementation UIScrollView (XPRefresherNotRecommanded)

- (void)xp_configRefreshCanRefresh:(BOOL)canRefresh canLoadMore:(BOOL)canLoadMore handler:(XPRefreshHandler)handler {
    self.xp_refresher = [[XPRefresher alloc] initWithScrollView:self canRefresh:canRefresh canLoadMore:canLoadMore];
    [self.xp_refresher _addHandler:handler];
}

@end
