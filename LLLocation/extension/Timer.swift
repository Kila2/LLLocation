//
//  Timer.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/28.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation

internal extension Timer {
    func pause(){
        self.fireDate = Date.distantFuture
    }
    
    func remuse(){
        self.fireDate = Date.distantPast
    }
}
