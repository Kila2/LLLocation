//
//  LLLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

public enum LLMode {
    /// one location
    case LastOne
    /// many localtions
    case RealTime
    /// many localtions when on background user can get some info
    case Running
    /// many localtions use for update map annotation
    case UpdateMap
    /// many locations but running on background
    case Tracking
    /// some localtions < 20/day can run on app suppend
    case Monitor
}

let ErrorKey = "kErrorKey"

internal struct LocationManagerError: Error {
    enum ErrorKind {
        case LocationFailed
    }
    let kind: ErrorKind
}

public class LLLocationKit {
    public static func initialize(with launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil{
            LocationShareModel.shareModel.appIsSuppend = .Suppend
        }
    }
}

public class LLLocationManager:NSObject,CLLocationManagerDelegate {
    public static let shareInstance = LLLocationManager.init();
    private static let tag = "LLLocationManager";
    
    public var maxAccuracy = Double.greatestFiniteMagnitude
    
    public var enableBackgroundTask:Bool {
        set {
            _enableBackgroundTask = newValue;
            if _enableBackgroundTask {
                self.addObserver();
            }
            else {
                self.removeObserver();
            }
        }
        get {
            return _enableBackgroundTask;
        }
    }
    
    public var enableSuppendBackground:Bool {
        set {
            _enableSuppendBackground = newValue
            if _enableSuppendBackground {
                self.manager.startMonitoringSignificantLocationChanges()
            }
            else {
                self.manager.stopMonitoringSignificantLocationChanges()
            }
        }
        get {
            return _enableSuppendBackground
        }
    }
    
    var startTime:TimeInterval {
        get {
            return TimeInterval.init(10)
        }
    }
    
    var stopTime:TimeInterval {
        get {
            return  TimeInterval.init(50)
        }
    }
    
    private var timerPool = TimerPool()
    private var _enableBackgroundTask = false;
    private var _enableSuppendBackground = false
    private var manager:CLLocationManager
    private var shareModel:LocationShareModel
    private var isStart = false;
    
    //public
    public override init() {
        LLLog.v(LLLocationManager.tag,"LLLocationManager init")
        manager = CLLocationManager();
        shareModel = LocationShareModel.shareModel;
        super.init()
        manager.initManager();
        manager.delegate = self;
        
    }
    
    deinit {
        LLLog.v(LLLocationManager.tag,"LLLocationManager deinit")
    }
    
    public func start() {
        guard CLLocationManager.locationServicesEnabled() else {
            LLLog.v(LLLocationManager.tag, "Location Services Disabled")
            return
        }
        
        guard UIApplication.shared.backgroundRefreshStatus == .available else {
            LLLog.v(LLLocationManager.tag, "Background Refresh Disabled")
            return
        }
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedAlways && authorizationStatus != .authorizedWhenInUse {
            LLLog.v(LLLocationManager.tag, "Location Authority Disabled")
            self.manager.requestAlwaysAuthorization()
            return
        }
        manager.startUpdatingLocation();
    }
    
    public func stop() {
        manager.stopUpdatingLocation();
    }
}

// MARK: - CLLocationManagerDelegate
extension LLLocationManager {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            manager.startUpdatingLocation();
            break;
        case .authorizedWhenInUse:
            manager.startUpdatingLocation();
            break;
        case .denied:
            LLLog.v(LLLocationManager.tag, "CLAuthorizationStatus Denied")
            break;
        case .restricted:
            LLLog.v(LLLocationManager.tag, "CLAuthorizationStatus Restricted")
            break;
        case .notDetermined:
            LLLog.v(LLLocationManager.tag, "CLAuthorizationStatus notDetermined")
            fallthrough
        default:
            break;
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.max { (location1, location2) -> Bool in
            return location1.horizontalAccuracy > location2.horizontalAccuracy
        }
        if let theAccuary = location?.horizontalAccuracy {
            if theAccuary > 0 && theAccuary <= maxAccuracy && -location!.timestamp.timeIntervalSinceNow < 4 {
                self.shareModel.locations.append(location!)
                LLLog.v(LLLocationManager.tag, location!.description)
            }
        }
        
        self.shareModel.lastKnowLocation = locations.first
        
        self.didUpdateLocationsHook();
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
        
        self.didFailWithErrorHook(error)
    }
    
    //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
    @objc private func didFailWithError(timer:Timer) {
        let userInfo = timer.userInfo as! Dictionary<String, Any>
        let error = userInfo[ErrorKey] as! Error
        self.locationManager(self.manager, didFailWithError: error)
        LLLog.v(LLLocationManager.tag, "didFailWithError")
    }
}


// MARK: - Timer
extension LLLocationManager {
    // MARK: Private Methods
    @objc internal func startLocationUpdatesByTimer(timer:Timer) {
        self.shareModel.startAfterTimer?.pause()
        self.shareModel.startAfterTimer = nil
        
        self.manager.initManager()
        self.manager.startUpdatingLocation()
    }
    
    @objc internal func stopLocationUpdatesByTimer(timer:Timer) {
        self.shareModel.stopAfterTimer?.pause()
        self.shareModel.stopAfterTimer = nil
        
        self.manager.stopUpdatingLocation()
        
        //Delay Restart
        if self.shareModel.startAfterTimer == nil {
            LLLog.v(LLLocationManager.tag, "Location manager restart Updating after \(stopTime) seconds")
            self.shareModel.startAfterTimer = self.timerPool.startAfterTimers(stopTime: stopTime, target: self)
            self.shareModel.startAfterTimer?.remuse(after: stopTime)
        }
        
    }
}

// MARK: - Observer
extension LLLocationManager {
    
    private func addObserver() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(LLLocationManager.applicationEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notification
    @objc private func applicationEnterBackground() {
        if enableBackgroundTask {
            manager.initManager()
            manager.requestAlwaysAuthorization()
            manager.startUpdatingLocation()
            self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
            _ = self.shareModel.bgTask?.beginNewBackgroundTask()
        }
    }
}

// MARK: - timer and backgroundtask
extension LLLocationManager {
    private func didUpdateLocationsHook() {
        if self.shareModel.retryAfterTimer != nil {
            self.shareModel.retryAfterTimer?.invalidate()
            self.shareModel.retryAfterTimer = nil
        }
        
        //TODO:Bk
        self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
        _ = self.shareModel.bgTask?.beginNewBackgroundTask()
        
        if self.shareModel.stopAfterTimer == nil {
            LLLog.v(LLLocationManager.tag, "Location manager stop Updating after \(startTime) seconds")
            self.shareModel.stopAfterTimer = self.timerPool.stopAfterTimers(loggingTime: startTime, target: self)
            self.shareModel.stopAfterTimer?.remuse(after: startTime)
        }
    }
    
    private func didFailWithErrorHook(error: Error) {
        if let error = error as? LocationManagerError {
            if error.kind == .LocationFailed && UIApplication.shared.applicationState == .background {
                //TODO:Bk
                self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
                _ = self.shareModel.bgTask?.beginNewBackgroundTask()
                
                guard self.shareModel.retryAfterTimer == nil else {
                    return
                }
                self.shareModel.retryAfterTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(LLLocationManager.didFailWithError(timer:)), userInfo: [ErrorKey:error], repeats: true)
            }
        }
    }
    
}
