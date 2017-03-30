//
//  Rule.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation

public class Rule {
    public var detail:[(loging:TimeInterval,stoping:TimeInterval)]!
    private var _logingIndex = 0
    
    public var logingIndex:Int? {
        get {
            return _logingIndex + 1 > detail.count ? nil : _logingIndex
        }
        set {
            _logingIndex = newValue!
        }
    }
    
    public func currentStatus()-> (loging:TimeInterval,stoping:TimeInterval) {
        if let index = logingIndex {
            let result = detail[index]
            logingIndex = index+1 > detail.count ? 0 : index+1
            return result
        }
        return (10,160)
    }
    
    public func resetIndex() {
        logingIndex = 0
    }
}
