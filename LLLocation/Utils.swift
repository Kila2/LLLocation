//
//  Utils.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/20.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation

class Utils {
    class func jumpToAppSetting() {
        let urlString = URL(string: UIApplicationOpenSettingsURLString)!
        if #available(iOS 10.0, *) {
            
            UIApplication.shared.open(urlString, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(urlString)
            
        }
    }
    class func jumpToLocationServiceSetting() {
        let urlString = URL(string: "prefs:root=LOCATION_SERVICES")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(urlString, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(urlString)
            
        }
    }
}
