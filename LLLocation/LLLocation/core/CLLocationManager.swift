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
        self.pausesLocationUpdatesAutomatically = false
    }
}
