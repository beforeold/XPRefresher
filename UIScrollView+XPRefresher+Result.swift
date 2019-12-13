//   
//   UIScrollView+XPRefresher+Result.swift
//   Brook
//   
//   Created  by Brook on 2019/5/22
//   Modified by Brook
//   Copyright © 2019年 Brook. All rights reserved.
//   
   

import UIKit

extension UIScrollView {
    func xp_endRefresherWith<Failure>(result: Result<Bool, Failure>) where Failure: Error {
        switch result {
        case .success(let hasMore):
            xp_endRefresher(withSucceed: true, hasMore: XPHasMoreMakeWithBool(hasMore))
        default:
            xp_endRefresher(withSucceed: false, hasMore: nil)
        }
    }
}
