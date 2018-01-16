//
//  TimerPool.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/28.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
internal class TimerPool {
    private static let tag = "TimerPool"
    private var _startAfterTimers = [TimeInterval:Timer]()
    private var _stopAfterTimers = [TimeInterval:Timer]()
    
    init() {
        LLLog.v(TimerPool.tag, "TimerPool init")
    }
    
    deinit {
        LLLog.v(TimerPool.tag, "TimerPool deinit")
    }
    
    internal func startAfterTimers(stopTime:TimeInterval,target:Any) -> Timer! {
        //pause old timer
        if LocationShareModel.shareModel.startAfterTimer != nil {
            LocationShareModel.shareModel.startAfterTimer?.pause()
        }
        
        if _startAfterTimers[stopTime] == nil {
            _startAfterTimers[stopTime] = Timer.scheduledTimer(timeInterval: stopTime, target: target, selector: #selector(LLLocationManager.startLocationUpdatesByTimer), userInfo: nil, repeats: true)
        }
        //pause new timer
        _startAfterTimers[stopTime]?.pause()
        return _startAfterTimers[stopTime]
    }
    
    internal func stopAfterTimers(loggingTime:TimeInterval,target:Any) -> Timer! {
        //pause old timer
        if LocationShareModel.shareModel.stopAfterTimer != nil {
            LocationShareModel.shareModel.stopAfterTimer?.pause()
        }
        
        if _stopAfterTimers[loggingTime] == nil {
            _stopAfterTimers[loggingTime] = Timer.scheduledTimer(timeInterval: loggingTime, target: target, selector: #selector(LLLocationManager.stopLocationUpdatesByTimer), userInfo: nil, repeats: true)
        }
        //pause new timer
        _stopAfterTimers[loggingTime]?.pause()
        return _stopAfterTimers[loggingTime]
    }
    
}
