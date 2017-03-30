//
//  TimerPool.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/28.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
internal class TimerPool {
    private var _startAfterTimers = [TimeInterval:Timer]()
    private var _stopAfterTimers = [TimeInterval:Timer]()
    
    internal func startAfterTimers(startTime:TimeInterval,target:Any) -> Timer! {
        //pause old timer
        if LocationShareModel.shareModel.startAfterTimer != nil {
            LocationShareModel.shareModel.startAfterTimer?.pause()
        }
        
        if _startAfterTimers[startTime] == nil {
            _startAfterTimers[startTime] = Timer.scheduledTimer(timeInterval: startTime, target: target, selector: #selector(BaseLocationManager.startLocationUpdatesByTimer), userInfo: nil, repeats: true)
        }
        //remuse new timer
        _startAfterTimers[startTime]?.remuse()
        return _startAfterTimers[startTime]
    }
    
    internal func stopAfterTimers(stopTime:TimeInterval,target:Any) -> Timer! {
        //pause old timer
        if LocationShareModel.shareModel.stopAfterTimer != nil {
            LocationShareModel.shareModel.stopAfterTimer?.pause()
        }
        
        if _stopAfterTimers[stopTime] == nil {
            _stopAfterTimers[stopTime] = Timer.scheduledTimer(timeInterval: stopTime, target: self, selector: #selector(BaseLocationManager.stopLocationUpdatesByTimer), userInfo: nil, repeats: true)
        }
        //remuse new timer
        _stopAfterTimers[stopTime]?.remuse()
        return _stopAfterTimers[stopTime]
    }
    
}
