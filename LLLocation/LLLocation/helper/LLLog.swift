//
//  LLLog.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/20.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation
import UIKit

class LLLog {
    final class func v(_ tag:String,_ msg:String) {
        print("--\(tag)--\n\(msg)")
//        if UserDefaults.standard.value(forKey: "Array") == nil {
//            UserDefaults.standard.setValue(Array<String>.init(), forKey: "Array");
//        }
//        var array:Array<String> = UserDefaults.standard.value(forKey: "Array") as! Array<String>
//        array.append("--\(tag)--\n\(msg)");
//        UserDefaults.standard.setValue(array, forKey: "Array")
//        UserDefaults.standard.synchronize();        
    }
}
