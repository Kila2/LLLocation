//
//  LocationShareModel.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/20.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationShareModel {
    
    public static var shareModel = LocationShareModel()
    public var lastKnowLocation: CLLocation?
    internal var stopAfterTimer:Timer?
    internal var startAfterTimer:Timer?
    internal var retryAfterTimer:Timer?
    internal var bgTask:BackgroundTaskManager?
    public var locations: [CLLocation]! {
        get {
            if _locations == nil {
                _locations = []
            }
            return _locations
        }
        set {
            _locations = newValue
        }
    }
    
    private var _locations: [CLLocation]?
    
}
