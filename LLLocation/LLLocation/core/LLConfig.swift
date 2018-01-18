//
//  LLConfig.swift
//  LLLocation
//
//  Created by lijunliang on 2018/1/18.
//  Copyright © 2018年 Kila. All rights reserved.
//

import UIKit

internal struct LLConfig {
    internal weak var weakManager:LLLocationManager?;
    internal var enableBackgroundTask:Bool {
        set {
            _enableBackgroundTask = newValue;
            if _enableBackgroundTask {
                if #available(iOS 9.0, *) {
                    weakManager?.manager.allowsBackgroundLocationUpdates = true
                }
                weakManager?.addObserver();
                
            }
            else {
                if #available(iOS 9.0, *) {
                    weakManager?.manager.allowsBackgroundLocationUpdates = false
                }
                weakManager?.removeObserver();
            }
        }
        get {
            return _enableBackgroundTask;
        }
    }
    
    internal var showsBackgroundLocationIndicator:Bool {
        get{
            return _showsBackgroundLocationIndicator;
        }
        set{
            _showsBackgroundLocationIndicator = newValue;
            if(_showsBackgroundLocationIndicator){
                if #available(iOS 11.0, *) {
                    weakManager?.manager.showsBackgroundLocationIndicator = true;
                }
            }
            else {
                if #available(iOS 11.0, *) {
                    weakManager?.manager.showsBackgroundLocationIndicator = false;
                }
            }
        }
    }
    
    internal var enableSuppendBackground:Bool {
        set {
            _enableSuppendBackground = newValue
            if _enableSuppendBackground {
                weakManager?.manager.startMonitoringSignificantLocationChanges()
            }
            else {
                weakManager?.manager.stopMonitoringSignificantLocationChanges()
            }
        }
        get {
            return _enableSuppendBackground
        }
    }
    
    internal var enableTimer:Bool {
        get{
            return _enableTimer
        }
        set {
            _enableTimer = newValue
        }
    }
    
    internal var startTime:TimeInterval = TimeInterval.init(10);
    
    internal var stopTime:TimeInterval = TimeInterval.init(50);
    internal var stopAfterGetFirstLocation = false;
    private var _enableTimer = false;
    private var _enableBackgroundTask = false;
    private var _enableSuppendBackground = false
    private var _showsBackgroundLocationIndicator = false;
}
