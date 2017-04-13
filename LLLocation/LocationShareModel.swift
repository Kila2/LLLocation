//
//  LocationShareModel.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/20.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

public enum AppIsSuppend: String {
    case Forground
    case Background
    case Suppend
}

public class LocationShareModel:NSObject {
    
    public static var shareModel = LocationShareModel()
    public var lastKnowLocation: CLLocation?
    public var appIsSuppend:AppIsSuppend = .Forground
    internal var stopAfterTimer:Timer?
    internal var startAfterTimer:Timer?
    internal var retryAfterTimer:Timer?
    internal var bgTask:BackgroundTaskManager?
    public var locations: ArrayProxy<CLLocation>! {
        get {
            if _locations == nil {
                _locations = ArrayProxy<CLLocation>()
            }
            return _locations
        }
        set {
            _locations = newValue
        }
    }
    private var _locations: ArrayProxy<CLLocation>?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(LocationShareModel.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationShareModel.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidEnterBackground() {
        appIsSuppend = .Background
    }
    
    func applicationWillEnterForeground() {
        appIsSuppend = .Forground
    }
    
}
