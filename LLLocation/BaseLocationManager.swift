//
//  BaseLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

public enum LLError {
    case DisableGlobleLocationService
    case DisableBackgroundFetch
    case DisableAppLocationAuth
    case RestrictAppLocationAuth
}

public struct LocationManagerError: Error {
    enum ErrorKind {
        case LocationFailed
    }
    let kind: ErrorKind
}

public protocol LocationManagerErrorDelegate:class {
    func startTrackingFailed(error: LLError)
}

let CLLocationManagerKey = "kCLLocationManagerKey"
let ErrorKey = "kErrorKey"
let DelegateKey = "kDelegateKey"

public class BaseLocationManager:CLLocationManager {
    static let TAG = "BaseLocationManager"
    var shareModel:LocationShareModel
    // MARK: Private Method
    fileprivate weak var timerPool = TimerPool()
    private var rule:Rule = Rule.init(with: [(loging: 10 , stoping: 50)])
    // MARK: Public Property
    weak var errorDelegate:LocationManagerErrorDelegate?
    var maxAccuracy = Double.greatestFiniteMagnitude
    var startTime:TimeInterval! {
        get {
            return rule.currentStatus().loging
        }
    }
    var stopTime:TimeInterval! {
        get {
            return rule.currentStatus().stoping
        }
    }
    
    public var currentRule:Rule! {
        set {
            if rule !== newValue {
                rule = newValue
            }
        }
        get {
            return rule
        }
    }
    
    // MARK: CLLocationManager Life Cycle
    public override init() {
        self.shareModel = LocationShareModel.shareModel
        super.init()
    }
    
    convenience init(rule:Rule) {
        self.init()
        self.currentRule = rule
    }
    // MARK: Public Method
    
    
    // MARK: Private Methods
    @objc internal func startLocationUpdatesByTimer(timer:Timer) {
    
        self.initManager()
        self.startUpdatingLocation()
    }
    
    @objc internal func stopLocationUpdatesByTimer(timer:Timer) {
        self.stopUpdatingLocation()
        "Location manager stop Updating after \(stopTime) seconds".showOnConsole(BaseLocationManager.TAG)
        //Delay Restart
        self.shareModel.startAfterTimer = self.timerPool!.startAfterTimers(startTime: startTime, target: self)
    }
    
    internal func start(delegate:CLLocationManagerDelegate) {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location Services Disabled")
            if self.errorDelegate != nil {
                self.errorDelegate?.startTrackingFailed(error: .DisableGlobleLocationService)
                return
            }
            Utils.jumpToLocationServiceSetting()
            return
        }
        
        guard UIApplication.shared.backgroundRefreshStatus == .available else {
            print("Background Refresh Disabled")
            if self.errorDelegate != nil {
                self.errorDelegate?.startTrackingFailed(error: .DisableBackgroundFetch)
                return
            }
            Utils.jumpToAppSetting()
            return
        }
        
        self.delegate = delegate
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedAlways && authorizationStatus != .authorizedWhenInUse {
            print("Location Authority Disabled")
            DispatchQueue.main.async {
                self.requestAlwaysAuthorization()
            }
            if self.errorDelegate != nil {
                self.errorDelegate?.startTrackingFailed(error: .DisableAppLocationAuth)
                return
            }
            Utils.jumpToAppSetting()
            return
        }
        // authorized
        self.initManager()
        self.startUpdatingLocation()
    }
    
    internal func cancel() {
        self.stopUpdatingLocation()
    }
    
    
    // MARK: Notification
    
}

internal extension BaseLocationManager {
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation], taskBlock:(()->Void)? = nil ){
        for location in locations {
            let theAccuary = location.horizontalAccuracy
            if theAccuary > 0 && theAccuary <= maxAccuracy {
                self.shareModel.locations.append(location)
                location.description.showOnConsole(BaseLocationManager.TAG)
            }
        }
        
        if self.shareModel.retryAfterTimer != nil {
            self.shareModel.retryAfterTimer?.invalidate()
            self.shareModel.retryAfterTimer = nil
        }
        
        self.shareModel.lastKnowLocation = locations.first
        taskBlock?()
        self.shareModel.stopAfterTimer = self.timerPool!.stopAfterTimers(stopTime: stopTime, target: self)
    }
    
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error, taskBlock:(()->Void)?=nil ) {
        
        //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
        if let error = error as? CLError {
            if error.code == .locationUnknown {
                if UIApplication.shared.applicationState == .background {
                    self.locationManager(manager , didFailWithError: LocationManagerError(kind: .LocationFailed), taskBlock: taskBlock)
                }
            }
        }
        
        if let error = error as? LocationManagerError {
            if error.kind == .LocationFailed && UIApplication.shared.applicationState == .background {
                taskBlock?()
                guard self.shareModel.retryAfterTimer == nil else {
                    return
                }
                self.shareModel.retryAfterTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(BaseLocationManager.didFailWithError(timer:)), userInfo: [ErrorKey:error], repeats: true)
            }
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:return
        case .authorizedAlways: break
        case .authorizedWhenInUse:break
        default:
            print("Location Authority restricted")
            if let errorDelegate = errorDelegate {
                errorDelegate.startTrackingFailed(error: .RestrictAppLocationAuth)
                return
            }
            Utils.jumpToAppSetting()
            return
        }
        manager.initManager()
        manager.startUpdatingLocation()
    }
    
    //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
    @objc private func didFailWithError(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, Any>
        let error = userInfo[ErrorKey] as! Error
        self.locationManager(self, didFailWithError: error)
        "didFailWithError".showOnConsole(BaseLocationManager.TAG)
    }
    
}
