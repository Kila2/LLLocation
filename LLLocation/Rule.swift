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
    
    public init() {
        
    }
    
    public convenience init(with detail:[(loging:TimeInterval,stoping:TimeInterval)]!) {
        self.init()
        if detail.count>0 {
            self.detail = detail
        }
        else {
            assert(false,"Rule detail size is zero")
        }
    }
    
    public func currentStatus()-> (loging:TimeInterval,stoping:TimeInterval) {
        if logingIndex != nil {
            let result = detail[_logingIndex]
            return result
        }
        return (10,160)
    }
    
    
    public func resetIndex() {
        logingIndex = 0
    }
    
    public func next() {
        _logingIndex = _logingIndex + 1 >= detail.count ? 0 : _logingIndex + 1
    }
}
