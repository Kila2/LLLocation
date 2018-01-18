//
//  LocationShareModel.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/20.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

internal enum AppIsSuppend: Int {
    case Forground
    case Background
    case Suppend
}

@objcMembers
public class LocationShareModel:NSObject {
    
    public static let shareModel = LocationShareModel()
    public var lastKnowLocation: CLLocation?
    public var locations: ArrayPorxy<CLLocation>
    
    internal var appIsSuppend:AppIsSuppend = .Forground
    internal var stopAfterTimer:Timer?
    internal var startAfterTimer:Timer?
    internal var retryAfterTimer:Timer?
    internal var bgTask:BackgroundTaskManager?
    
    override init() {
        locations = ArrayPorxy<CLLocation>.init();
        super.init()
        NotificationCenter.default.addObserver(self, selector:#selector(LocationShareModel.applicationDidEnterBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(LocationShareModel.applicationWillEnterForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidEnterBackground() {
        appIsSuppend = .Background
    }
    
    @objc private func applicationWillEnterForeground() {
        appIsSuppend = .Forground
    }
}
