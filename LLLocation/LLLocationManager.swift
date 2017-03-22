//
//  LLLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation

class LLLocationManager:BaseLocationManager {
    
    private var rule:Rule?
    public var currentRule:Rule? {
        set {
            if rule !== newValue {
                rule = newValue
            }
        }
        get {
            return rule
        }
    }
    
    private var _useInBackgroundTask = false
    public var useInBackgroundTask:Bool {
        set {
            _useInBackgroundTask = newValue
            if newValue {
                let delegateWithBackgroundTask = LLLocationManagerDelegateWithBackgroundTask(manager: self)
                self.delegate = delegateWithBackgroundTask
            }
            else {
            
            }
        }
        get {
            return _useInBackgroundTask
        }
    }
    public var useSuppendBackground = false
}
