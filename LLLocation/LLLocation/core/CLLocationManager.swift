//
//  CLLocationManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/3/22.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import CoreLocation

internal extension CLLocationManager {
    internal func initManager() {
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
