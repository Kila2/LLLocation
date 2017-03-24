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

public protocol LocationManagerDelegate:class {
    func startTrackingFailed(error: LLError)
    
}

let MaxRestTime: TimeInterval = 165
let MaxTaskTime: TimeInterval = 170
let MinCollectTaskTime: TimeInterval = 5

let CLLocationManagerKey = "kCLLocationManagerKey"
let ErrorKey = "kErrorKey"
let DelegateKey = "kDelegateKey"

public class BaseLocationManager:CLLocationManager {
    static let TAG = "BaseLocationManager"
    var shareModel:LocationShareModel
    // MARK: Public Property
    weak var errorDelegate:LocationManagerDelegate?
    var maxAccuracy = DBL_MAX
    var restartTime:TimeInterval!
    var delayStopTime:TimeInterval!
    
    // MARK: CLLocationManager Life Cycle
    public override init() {
        self.shareModel = LocationShareModel.shareModel
        super.init()
    }
    
    // MARK: Public Method
    
    
    // MARK: Private Methods
    @objc fileprivate func restartLocationUpdates(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, Any>
        let manager = userInfo[CLLocationManagerKey] as! CLLocationManager
        
        if self.shareModel.timer != nil {
            self.shareModel.timer?.invalidate()
            self.shareModel.timer = nil
        }
        manager.delegate = delegate
        manager.initManager()
        manager.startUpdatingLocation()
    }
    
    @objc fileprivate func stopLocationDelayBySeconds(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, Any>
        let manager = userInfo[CLLocationManagerKey] as! CLLocationManager
        manager.stopUpdatingLocation()
        "Location manager stop Updating after \(delayStopTime) seconds".showOnConsole(BaseLocationManager.TAG)
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
        if self.shareModel.timer != nil {
            self.shareModel.timer?.invalidate()
            self.shareModel.timer = nil
        }
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
        
        self.shareModel.lastKnowLocation = locations.first
        
        guard self.shareModel.timer == nil else {
            return
        }
        
        if self.shareModel.didFailedTimer != nil {
            self.shareModel.didFailedTimer?.invalidate()
            self.shareModel.didFailedTimer = nil
        }
        taskBlock?()
        
        self.shareModel.timer = Timer.scheduledTimer(timeInterval: restartTime, target: self, selector: #selector(BaseLocationManager.restartLocationUpdates), userInfo: [CLLocationManagerKey:manager], repeats: true)
        
        if self.shareModel.delayTimer != nil {
            self.shareModel.delayTimer?.invalidate()
            self.shareModel.delayTimer = nil
        }
        if restartTime == delayStopTime{
            self.shareModel.delayTimer = Timer.scheduledTimer(timeInterval: delayStopTime, target: self, selector: #selector(BaseLocationManager.stopLocationDelayBySeconds), userInfo: [CLLocationManagerKey:manager], repeats: false)
        }
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
                guard self.shareModel.didFailedTimer == nil else {
                    return
                }
                
                self.shareModel.didFailedTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(BaseLocationManager.didFailWithError(timer:)), userInfo: [CLLocationManagerKey:manager,ErrorKey:error], repeats: true)
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
        let manager = userInfo[CLLocationManagerKey] as! CLLocationManager
        let error = userInfo[ErrorKey] as! Error
        locationManager(manager, didFailWithError: error)
        "didFailWithError".showOnConsole(BaseLocationManager.TAG)
    }
    
}
