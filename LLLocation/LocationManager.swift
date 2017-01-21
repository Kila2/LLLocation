//
//  LocationManager.swift
//  location
//
//  Created by junlianglee on 2017/1/20.
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

struct LocationManagerError: Error {
    enum ErrorKind {
        case LocationFailed
    }
    let kind: ErrorKind
}

public protocol LocationManagerDelegate {
    func startTrackingFailed(error: LLError)
    
}

extension CLLocationManager {
    func initManager() {
        self.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.distanceFilter = kCLDistanceFilterNone
        if #available(iOS 9.0, *) {
            self.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
        self.pausesLocationUpdatesAutomatically = false
    }
}

let MaxRestTime: TimeInterval = 165
let MaxTaskTime: TimeInterval = 170
let MinCollectTaskTime: TimeInterval = 5
let CLLocationManagerKey = "CLLocationManagerKey"
let ErrorKey = "ErrorKey"

public class LocationManager: NSObject, CLLocationManagerDelegate {
    // MARK: Class Property
    static let TAG = "LocationManager"
    private static var _shareLocationManager: CLLocationManager?
    public class var shareLocationManager: CLLocationManager! {
        get {
            objc_sync_enter(self)
            if _shareLocationManager == nil {
                let manager = CLLocationManager()
                _shareLocationManager = manager
            }
            objc_sync_exit(self)
            return _shareLocationManager
        }
        set {
            _shareLocationManager = newValue
        }
    }
    // MARK: Public Property
    
    /*
     *  maxAccuracy
     *
     *  Discussion:
     *  Only save location where accuracy small or equal than maxAccuracy default is Double.Max
     */
    public var maxAccuracy = DBL_MAX
    
    public var delegate: LocationManagerDelegate?
    
    public var oneTaskTime: TimeInterval {
        get {
            if _oneTaskTime <=  MaxTaskTime {
                return _oneTaskTime
            }
            return MaxTaskTime
        }
        set {
            if  _oneTaskTime <= MaxTaskTime {
                _oneTaskTime = newValue
            }
            else {
                _oneTaskTime = MaxTaskTime
            }
        }
    }
    public var collectTaskTime: TimeInterval {
        get {
            if _collectTaskTime >= MinCollectTaskTime && _collectTaskTime<=oneTaskTime {
                return _collectTaskTime
            }
            else {
                return MinCollectTaskTime
            }
        }
        set {
            if _collectTaskTime >= MinCollectTaskTime  && _collectTaskTime<=oneTaskTime {
                _collectTaskTime = newValue
            }
            else {
                _collectTaskTime = MinCollectTaskTime
            }
        }
    }
    
    /*
     *  cpuRestTime
     *
     *  Discussion:
     *  This is cpu needs rest time in every 170s,it's shoul in range of 0...165.
     *  Where it's zero the manager is always collect location.
     */
    public var cpuRestTime: TimeInterval {
        return oneTaskTime - collectTaskTime
    }
    
    // MARK: Private Property
    /*
     *  delayStopTime
     *
     *  Discussion:
     *  Delay stop location manager to save power
     *  Min value is 5,beacuse locationmanager need some times to collect location
     */
    private var delayStopTime:TimeInterval {
        return collectTaskTime
    }
    
    
    /*
     *  restartTime
     *
     *  Discussion:
     *  This is get next location time, work on forgound default is 60s
     *  In backgorund it's equal MaxTaskTime
     */
    private var restartTime:TimeInterval{
        return oneTaskTime
    }
    
    private var _oneTaskTime: TimeInterval = MaxTaskTime
    private var _collectTaskTime: TimeInterval = MinCollectTaskTime
    
    private var shareModel: LocationShareModel!
    
    
    
    // MARK: NSObject Life Cycle
    public override init() {
        super.init()
        self.shareModel = LocationShareModel.shareModel
        NotificationCenter.default.addObserver(self, selector: #selector(LocationManager.applicationEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Public Method
    public func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location Services Disabled")
            if delegate != nil {
                self.delegate?.startTrackingFailed(error: .DisableGlobleLocationService)
                return
            }
            Utils.jumpToLocationServiceSetting()
            return
        }
        guard UIApplication.shared.backgroundRefreshStatus == .available else {
            print("Background Refresh Disabled")
            if delegate != nil {
                self.delegate?.startTrackingFailed(error: .DisableBackgroundFetch)
                return
            }
            Utils.jumpToAppSetting()
            return
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedAlways && authorizationStatus != .authorizedWhenInUse {
            print("Location Authority Disabled")
            let manager = LocationManager.shareLocationManager
            manager?.delegate = self
            DispatchQueue.main.async {
                manager?.requestAlwaysAuthorization()
            }
            if delegate != nil {
                self.delegate?.startTrackingFailed(error: .DisableAppLocationAuth)
                return
            }
            return
        }
        // authorized
        let locationManager = LocationManager.shareLocationManager
        locationManager?.delegate = self
        locationManager?.initManager()
        locationManager?.startUpdatingLocation()
    }
    
    public func stopTracking() {
        if self.shareModel.timer != nil {
            self.shareModel.timer?.invalidate()
            self.shareModel.timer = nil
        }
        let manager = LocationManager.shareLocationManager
        manager?.stopUpdatingLocation()
    }
    
    // MARK: Private Methods
    @objc private func restartLocationUpdates() {
        if self.shareModel.timer != nil {
            self.shareModel.timer?.invalidate()
            self.shareModel.timer = nil
        }
        
        let manager = LocationManager.shareLocationManager
        manager?.delegate = self
        manager?.initManager()
        manager?.startUpdatingLocation()
        
    }
    @objc private func stopLocationDelayBySeconds() {
        let manager = LocationManager.shareLocationManager
        manager?.stopUpdatingLocation()
        "Location manager stop Updating after \(delayStopTime) seconds".showOnConsole(LocationManager.TAG)
    }
    
    // MARK: Notification
    @objc private func applicationEnterBackground() {
        let manager = LocationManager.shareLocationManager
        manager?.delegate = self
        manager?.initManager()
        manager?.requestAlwaysAuthorization()
        manager?.startUpdatingLocation()
        self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
        _ = self.shareModel.bgTask?.beginNewBackgroundTask()
        
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.first?.description.showOnConsole(LocationManager.TAG)
        for location in locations {
            let theAccuary = location.horizontalAccuracy
            if theAccuary > 0 && theAccuary <= maxAccuracy {
                self.shareModel.locations.append(location)
                
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
        
        self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
        _ = self.shareModel.bgTask?.beginNewBackgroundTask()
        
        self.shareModel.timer = Timer.scheduledTimer(timeInterval: restartTime, target: self, selector: #selector(LocationManager.restartLocationUpdates), userInfo: nil, repeats: true)
        if self.shareModel.delayTimer != nil {
            self.shareModel.delayTimer?.invalidate()
            self.shareModel.delayTimer = nil
        }
        self.shareModel.delayTimer = Timer.scheduledTimer(timeInterval: delayStopTime, target: self, selector: #selector(LocationManager.stopLocationDelayBySeconds), userInfo: nil, repeats: false)
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        
        
        //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
        
        if let error = error as? CLError {
            if error.code == .locationUnknown {
                if UIApplication.shared.applicationState == .background {
                    self.locationManager(manager , didFailWithError: LocationManagerError(kind: .LocationFailed))
                }
            }
        }
        
        if let error = error as? LocationManagerError {
            if error.kind == .LocationFailed && UIApplication.shared.applicationState == .background {
                self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
                _ = self.shareModel.bgTask?.beginNewBackgroundTask()
                guard self.shareModel.didFailedTimer == nil else {
                    return
                }
                
                self.shareModel.didFailedTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(LocationManager.didFailWithError(timer:)), userInfo: [CLLocationManagerKey:manager,ErrorKey:error], repeats: true)
            }
        }
    }
    
    //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
    @objc private func didFailWithError(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, Any>
        let manager = userInfo[CLLocationManagerKey] as! CLLocationManager
        let error = userInfo[ErrorKey] as! Error
        locationManager(manager, didFailWithError: error)
        
        "didFailWithError".showOnConsole(LocationManager.TAG)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:return
        case .authorizedAlways: break
        case .authorizedWhenInUse:break
        default:
            print("Location Authority restricted")
            if delegate != nil {
                self.delegate?.startTrackingFailed(error: .RestrictAppLocationAuth)
                return
            }
            Utils.jumpToAppSetting()
            return
        }
        
        manager.initManager()
        manager.startUpdatingLocation()
    }
    
}
