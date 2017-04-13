//
//  LLLocationManagerDelegate.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

internal class LLLocationManagerDelegate:NSObject,CLLocationManagerDelegate {
    var manager:BaseLocationManager
    init(manager:BaseLocationManager) {
        self.manager = manager
        super.init()
        "LLLocationManagerDelegate init".showOnConsole("LLLocationManagerDelegate");
    }
    deinit {
        "LLLocationManagerDelegate deinit".showOnConsole("LLLocationManagerDelegate");
    }
}


internal class LLLocationManagerDelegateWithBackgroundTask:LLLocationManagerDelegate {
    
    // MARK: NSObject Life Cycle
    public override init(manager:BaseLocationManager) {
        super.init(manager: manager)
        "LLLocationManagerDelegateWithBackgroundTask init".showOnConsole("LLLocationManagerDelegateWithBackgroundTask");
    }
    
    deinit {
        "LLLocationManagerDelegateWithBackgroundTask deinit".showOnConsole("LLLocationManagerDelegateWithBackgroundTask");
        removeObserver()
    }
    
    public func addObserver() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(LLLocationManagerDelegateWithBackgroundTask.applicationEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    public func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notification
    @objc private func applicationEnterBackground() {
        if manager.delegate === LLLocationManagerDelegateWithBackgroundTask.self {
            manager.initManager()
            manager.requestAlwaysAuthorization()
            manager.startUpdatingLocation()
            self.manager.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
            _ = self.manager.shareModel.bgTask?.beginNewBackgroundTask()
        }
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.manager.locationManager(manager, didUpdateLocations: locations) {
            self.manager.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
            _ = self.manager.shareModel.bgTask?.beginNewBackgroundTask()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.manager.locationManager(manager, didFailWithError: error) {
            self.manager.shareModel.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager
            _ = self.manager.shareModel.bgTask?.beginNewBackgroundTask()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.manager.locationManager(manager, didChangeAuthorization: status)
    }
}



internal class LLLocationManagerDelegateWithNoBackgroundTask:LLLocationManagerDelegate {
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.manager.locationManager(manager, didUpdateLocations: locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.manager.locationManager(manager, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.manager.locationManager(manager, didChangeAuthorization: status)
    }
}

