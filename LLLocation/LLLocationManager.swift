//
//  LLLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

public class LLLocationManager:BaseLocationManager {
    
    
    public override init() {
        super.init()
    }
    
    public convenience init(rule:Rule) {
        self.init(rule: rule)
    }
    
    private var _delegateWithBT:LLLocationManagerDelegateWithBackgroundTask?
    internal var delegateWithBT:LLLocationManagerDelegateWithBackgroundTask! {
        get {
            if self._delegateWithBT == nil {
                self._delegateWithBT = LLLocationManagerDelegateWithBackgroundTask(manager: self)
            }
            return self._delegateWithBT
        }
    }
    
    private var _delegateWithOutBT:LLLocationManagerDelegateWithNoBackgroundTask?
    internal var delegateWithOutBT:LLLocationManagerDelegateWithNoBackgroundTask! {
        get {
            if self._delegateWithOutBT == nil {
                self._delegateWithOutBT = LLLocationManagerDelegateWithNoBackgroundTask(manager: self)
            }
            return self._delegateWithOutBT
        }
    }
    
    private var _useInBackgroundTask = false
    public var useInBackgroundTask:Bool {
        set {
            _useInBackgroundTask = newValue
            if newValue {
                self.delegate = self.delegateWithBT
                self.delegateWithBT.addObserver()
            }
            else {
                self.delegateWithBT.removeObserver()
                self.delegate = self.delegateWithOutBT
            }
            
        }
        get {
            return _useInBackgroundTask
        }
    }
    public var useSuppendBackground = false
    
    //MARK: Control
    public func start() {
        super.start(delegate: dispathDelegate())
    }
    public override func cancel(){
        super.cancel()
    }
    
    func dispathDelegate()->LLLocationManagerDelegate {
        return useInBackgroundTask ? delegateWithBT : delegateWithOutBT
    }
    
}
