//
//  LLLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation



let ErrorKey = "kErrorKey"

@objc public enum LLMode:Int {
    /// many locations save power every 1min work 10s
    case Default
    /// one location
    case LastOne
    /// many locations
    case RealTime
    /// many locations when on background user can get some info
    case Running
    /// many locations use for update map annotation
    case UpdateMap
    /// many locaions but running on background
    case Navgation
    /// many locaions
    case Tracking
    /// some locations < 20/day can run on app suppend
    case Monitor
    /// some locations every 500m
    case Bus
    /// some locations every 1000m
    case Train
    /// always use need more power
    case Always
}



/// init LLLocationKit at AppDelegate for get UIApplicationLaunchOptionsKey
public class LLLocationKit {
    @objc public static func initialize(with launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil{
            LocationShareModel.shareModel.appIsSuppend = .Suppend
        }
    }
}


public class LLLocationManager:NSObject,CLLocationManagerDelegate {
    @objc public static let shareInstance = LLLocationManager.init();
    fileprivate static let tag = "LLLocationManager";
    
    /// if location horizontalAccuracy smaller than maxAccuracy it will not record default = DOUBLE_MAX
    @objc public var maxAccuracy = Double.greatestFiniteMagnitude
    
    /// set reocrd location mode
    @objc public var mode:LLMode {
        set {
            self.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            self.manager.distanceFilter = kCLDistanceFilterNone
            if #available(iOS 11.0, *) {
                self.manager.showsBackgroundLocationIndicator = false;
            }
            config.enableBackgroundTask = false;
            config.enableSuppendBackground = false;
            config.enableTimer = false;
            config.stopAfterGetFirstLocation = false;
            config.showsBackgroundLocationIndicator = false;
            config.startTime = TimeInterval.init(10);
            config.stopTime = TimeInterval.init(50);
            
            _mode = newValue;
            switch newValue {
            case .Default:
                config.enableTimer = true;
                break;
            case .LastOne:
                config.stopAfterGetFirstLocation = true;
                break;
            case .RealTime:
                break;
            case .Running:
                config.enableBackgroundTask = true;
                config.showsBackgroundLocationIndicator = true;
                break;
            case .Bus:
                self.manager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
                self.manager.distanceFilter = 500;
                break;
            case .Train:
                self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
                self.manager.distanceFilter = 1000;
                break;
            case .UpdateMap:
                break;
            case .Navgation:
                config.enableBackgroundTask = true;
                config.showsBackgroundLocationIndicator = true;
                break;
            case .Tracking:
                config.enableSuppendBackground = true;
                break;
            case .Monitor:
                config.enableSuppendBackground = true;
                break;
            case .Always:
                config.enableBackgroundTask = true;
                config.enableSuppendBackground = true;
                config.enableTimer = true;
                break;
            }
        }
        get {
            return self._mode
        }
    }
    
    fileprivate var config:LLConfig
    fileprivate var _mode:LLMode = .Default;
    fileprivate var timerPool = TimerPool()
    
    internal var manager:CLLocationManager
    fileprivate var shareModel:LocationShareModel
    fileprivate var isStart = false;
    
    
    /// init
    public override init() {
        LLLog.v(LLLocationManager.tag,"LLLocationManager init")
        manager = CLLocationManager();
        shareModel = LocationShareModel.shareModel;
        config = LLConfig.init()
        super.init()
        manager.initManager();
        manager.delegate = self;
        config.weakManager = self;
        mode = .Running;
        
    }
    
    deinit {
        LLLog.v(LLLocationManager.tag,"LLLocationManager deinit")
    }
    
    
    /// start record location
    @objc public func start() {
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
    
    /// stop record location
    @objc public func stop() {
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
            if theAccuary > 0 && theAccuary <= maxAccuracy {
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
        
        self.didFailWithErrorHook(error: error)
    }
    
    //need to test sometimes it's always failed about 3 min there is no background task work,so app will stop
    @objc fileprivate func didFailWithError(timer:Timer) {
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
            LLLog.v(LLLocationManager.tag, "Location manager restart Updating after \(config.stopTime) seconds")
            self.shareModel.startAfterTimer = self.timerPool.startAfterTimers(stopTime: config.stopTime, target: self)
            self.shareModel.startAfterTimer?.remuse(after: config.stopTime)
        }
        
    }
}

// MARK: - Observer
extension LLLocationManager {
    
    internal func addObserver() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(LLLocationManager.applicationEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    internal func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notification
    @objc fileprivate func applicationEnterBackground() {
        self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
        _ = self.shareModel.bgTask?.beginNewBackgroundTask()
    }
}

// MARK: - timer and backgroundtask
extension LLLocationManager {
    fileprivate func didUpdateLocationsHook() {
        
        if(config.stopAfterGetFirstLocation){
            self.stop();
        }
        else {
            
            if config.enableTimer&&self.shareModel.retryAfterTimer != nil {
                self.shareModel.retryAfterTimer?.invalidate()
                self.shareModel.retryAfterTimer = nil
            }
            if(config.enableBackgroundTask) {
                //TODO:Bk
                self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
                _ = self.shareModel.bgTask?.beginNewBackgroundTask()
            }
            if config.enableTimer&&self.shareModel.stopAfterTimer == nil {
                LLLog.v(LLLocationManager.tag, "Location manager stop Updating after \(config.startTime) seconds")
                self.shareModel.stopAfterTimer = self.timerPool.stopAfterTimers(loggingTime: config.startTime, target: self)
                self.shareModel.stopAfterTimer?.remuse(after: config.startTime)
            }
        }
    }
    
    fileprivate func didFailWithErrorHook(error: Error) {
        if let error = error as? LocationManagerError {
            if error.kind == .LocationFailed && UIApplication.shared.applicationState == .background {
                //TODO:Bk
                if(config.enableBackgroundTask) {
                    //TODO:Bk
                    self.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
                    _ = self.shareModel.bgTask?.beginNewBackgroundTask()
                }
                
                guard config.enableTimer == false,self.shareModel.retryAfterTimer == nil else {
                    return
                }
                self.shareModel.retryAfterTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(LLLocationManager.didFailWithError(timer:)), userInfo: [ErrorKey:error], repeats: true)
            }
        }
    }
    
}
