//
//  LLLocationManagerDelegate.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

class LLLocationManagerDelegate:NSObject,CLLocationManagerDelegate {
    var manager:BaseLocationManager
    init(manager:BaseLocationManager) {
        self.manager = manager
        super.init()
    }
}

class LLLocationManagerDelegateWithBackgroundTask:LLLocationManagerDelegate {
    
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
