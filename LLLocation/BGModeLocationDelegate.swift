//
//  BGModeLocationDelegate.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

let CLLocationManagerKey = "CLLocationManagerKey"
let ErrorKey = "ErrorKey"

class BGModeLocationDelegate : NSObject , CLLocationManagerDelegate {
    
    private var shareModel: LocationShareModel
    
    override init() {
        self.shareModel = LocationShareModel.shareModel
    }
    
    override init() {
        
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for location in locations {
            let theAccuary = location.horizontalAccuracy
            if theAccuary > 0 && theAccuary <= maxAccuracy {
                self.shareModel.locations.append(location)
                location.description.showOnConsole(LocationManager.TAG)
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
        if restartTime == delayStopTime{
            self.shareModel.delayTimer = Timer.scheduledTimer(timeInterval: delayStopTime, target: self, selector: #selector(LocationManager.stopLocationDelayBySeconds), userInfo: nil, repeats: false)
        }
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
                
                self.shareModel.didFailedTimer = Timer.scheduledTimer(timeInterval: 170, target: self, selector: #selector(BGModeLocationDelegate.didFailWithError(timer:)), userInfo: [CLLocationManagerKey:manager,ErrorKey:error], repeats: true)
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
    
    
}
