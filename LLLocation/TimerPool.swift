//
//  TimerPool.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/28.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
class TimerPool {
    var startAfterTimers = [Int:Timer]()
    var stopAfterTimers = [Int:Timer]()
    var retryAfterTimers = [Int:Timer]()
}
