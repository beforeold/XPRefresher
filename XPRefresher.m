//
//  XPRefresher.m
//  Brook
//
//  Created by Brook on 2017/5/25.
//  Copyright © 2017年 Brook. All rights reserved.
//

#import "XPRefresher.h"

#import "XPRefreshHeader.h"
#import "XPRefreshFooter.h"

static NSInteger const kBeforeRequestPage = 0;

typedef NS_ENUM(NSInteger, XPRefresherState) {
    XPRefresherStateIdle,
    XPRefresherStateRefresh,
    XPRefresherStateLoadMore,
};


static XPRefreshingContext XPRefreshingContextMake(BOOL isRefresh, BOOL isAnimated, NSInteger page) {
    XPRefreshingContext refresh;
    refresh.isRefresh = isRefresh;
    refresh.isAnimated = isAnimated;
    refresh.page = page;
    
    return refresh;
}

@interface XPRefresher ()

@property (nonatomic, weak, readonly) UIScrollView *scrollView;

@property (nonatomic, strong, readwrite) MJRefreshHeader *header;
@property (nonatomic, strong, readwrite) MJRefreshAutoNormalFooter *footer;

/// 是否可以进行上拉刷新
@property (nonatomic, assign, readonly) BOOL canLoadMore;
@property (nonatomic, assign) XPRefresherState state;

/// 存放回调的数组
@property (nonatomic, strong) NSMutableArray <XPRefreshHandler> *handlers;
@property (nonatomic, strong) NSMutableArray <XPRefresherCallback> *callbackArray;
@property (nonatomic, assign, readwrite) NSInteger page;
@property (nonatomic, assign) NSInteger previousPage;

@end

@interface UIScrollView (XPRefresherInternal)

- (NSInteger)xp_itemsCount;

@end

@implementation XPRefresher
- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                        canRefresh:(BOOL)canRefesh
                       canLoadMore:(BOOL)canLoadMore
{
    NSParameterAssert(scrollView);
    
    self = [super init];
    if (self) {
        
        scrollView.mj_header = nil;
        if (canRefesh) {
            _header = [self makeHeader];
            scrollView.mj_header = _header;
        }
        
        scrollView.mj_footer = nil;
        if (canLoadMore) {
            _footer = [self makeFooter];
        }
        
        _scrollView = scrollView;
        _canLoadMore = canLoadMore;
        _handlers = [NSMutableArray arrayWithCapacity:1];
        _callbackArray = [NSMutableArray arrayWithCapacity:1];
        _page = kBeforeRequestPage;
    }
    
    return self;
}

- (void)_addHandler:(XPRefreshHandler)handler {
    !handler ?: [_handlers addObject:[handler copy]];
}

- (void)addCallback:(XPRefresherCallback)callback {
    !callback ?: [_callbackArray addObject:[callback copy]];
}

- (void)startRefreshingAnimated:(BOOL)animated {
    if (animated) {
        [self.header beginRefreshing]; // 用下拉动画的形式触发 refreshDataWithSender
    } else {
        [self refreshDataWithSender:nil];
    }
}

- (void)startLoadingMoreAnimated:(BOOL)animated {
    if (animated) {
        [self.footer beginRefreshing]; // 用下拉动画的形式触发 refreshDataWithSender
    } else {
        [self loadMoreDataWithSender:nil];
    }
}

#pragma mark - event
/// 根据 是否有 sender 决定是否是强制刷新
static BOOL is_aniamted_with(id sender) { return !!sender; }
- (void)refreshDataWithSender:(id)sender {
    self.state = XPRefresherStateRefresh;
    
    self.previousPage = self.page;
    self.page = kBeforeRequestPage;
    
    self.page ++;
    
    __weak typeof(self) weakSelf = self;
    XPRequestEndCompletion refreshCompletion = [^(BOOL succeed, NSNull *hasMore){
        typeof(self) self = weakSelf; if (!self) return;
        [self endWithSucceed:succeed hasMore:hasMore];
    } copy];
    
    
    XPRefreshingContext context = XPRefreshingContextMake(YES, is_aniamted_with(sender), self.page);
    
    for (XPRefreshHandler handler in self.handlers) {
        handler(context, refreshCompletion);
    }
    
    for (XPRefresherCallback callback in self.callbackArray) {
        callback(context);
    }
}

- (void)loadMoreDataWithSender:(id)sender {
    self.state = XPRefresherStateLoadMore;
    
    self.previousPage = self.page;
    self.page ++;
    
    __weak typeof(self) weakSelf = self;
    XPRequestEndCompletion loadMoreCompletion = [^(BOOL succeed, NSNull *hasMore){
        typeof(self) self = weakSelf; if (!self) return;
        [self endWithSucceed:succeed hasMore:hasMore];
    } copy];
    
    XPRefreshingContext context = XPRefreshingContextMake(NO, is_aniamted_with(sender), self.page);
    for (XPRefreshHandler handler in _handlers) {
        handler(context, loadMoreCompletion);
    }
    
    for (XPRefresherCallback callback in self.callbackArray) {
        callback(context);
    }
}

#pragma mark - private methods
- (void)endWithSucceed:(BOOL)succeed hasMore:(NSNull *_Nullable)hasMore {
    if (self.state == XPRefresherStateRefresh) {
        [self endRefreshSucceed:succeed hasMore:hasMore];
    } else if (self.state == XPRefresherStateLoadMore) {
        [self endLoadMoreSucceed:succeed hasMore:hasMore];
    } else {
        [self endRefreshSucceed:succeed hasMore:hasMore]; // 在 idle 下调用，通过调用 refresh 的 handler 处理下 footer
    }
    
    self.state = XPEmptyReasonIdle;
}

- (void)endRefreshSucceed:(BOOL)succeed hasMore:(NSNull *)hasMore {
    if (succeed) {
        [self refreshSucceededAnyMore:hasMore];
    } else {
        [self refreshFailed];
    }
}

- (void)endLoadMoreSucceed:(BOOL)succeed hasMore:(NSNull *)hasMore {
    if (succeed) {
        [self loadMoreSucceededAnyMore:hasMore];
    } else {
        [self loadMoreFailed];
    }
    self.state = XPEmptyReasonIdle;
}

/// 刷新成功回执
- (void)refreshSucceededAnyMore:(NSNull *)hasMore {
    [self.header endRefreshing];
    
    if (!self.canLoadMore) return;
    
    if (!hasMore) {
        [self.scrollView.mj_footer endRefreshingWithNoMoreData];
        return;
    }
    
    if (!self.scrollView.mj_footer) {
        self.scrollView.mj_footer = self.footer;
    }
    [self.footer resetNoMoreData];
    [self.footer endRefreshing];
}

/// 刷新失败回执
- (void)refreshFailed {
    [self.header endRefreshing];
    self.page = self.previousPage;
}

/// 上拉成功回执
- (void)loadMoreSucceededAnyMore:(NSNull *)hasMore {
    if (hasMore) {
        [self.footer endRefreshing];
    } else {
        [self.footer endRefreshingWithNoMoreData];
    }
}

/// 上拉失败回执
- (void)loadMoreFailed {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0/*避免下拉时网络请求过快失败*/ * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.scrollView.mj_footer endRefreshing];
        self.page = self.previousPage;
        self.scrollView.mj_footer = nil; // 让 footer 下落
        self.scrollView.mj_footer = self.footer; // 重新设置 footer
    });
}

- (MJRefreshHeader *)makeHeader {
    Class clz = NSClassFromString(NSStringFromClass([XPRefreshHeader class]));
    MJRefreshHeader *header = [clz headerWithRefreshingTarget:self refreshingAction:@selector(refreshDataWithSender:)];
    return header;
}

- (MJRefreshAutoNormalFooter *)makeFooter {
    MJRefreshAutoNormalFooter *footer = nil;
    footer = [XPRefreshFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreDataWithSender:)];
    footer.stateLabel.font = kPingfangRegularFont(14);
    footer.stateLabel.textColor = kBrownGrey;
    footer.refreshingTitleHidden = YES;
    footer.height = RESIZE(80);
    [footer setTitle:XPLocalizedString(@"Already at the bottom") forState:MJRefreshStateNoMoreData];
    
    return footer;
}

@end


@implementation UIScrollView (XPRefresherInternal)

- (NSInteger)xp_itemsCount
{
    NSInteger items = 0;
    
    // UIScollView doesn't respond to 'dataSource' so let's exit
    if (![self respondsToSelector:@selector(dataSource)]) {
        return items;
    }
    
    // UITableView support
    if ([self isKindOfClass:[UITableView class]]) {
        
        UITableView *tableView = (UITableView *)self;
        id <UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    }
    // UICollectionView support
    else if ([self isKindOfClass:[UICollectionView class]]) {
        
        UICollectionView *collectionView = (UICollectionView *)self;
        id <UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            for (NSInteger section = 0; section < sections; section++) {
                items += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    
    return items;
}

@end
