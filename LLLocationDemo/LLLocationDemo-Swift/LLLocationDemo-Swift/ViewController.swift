//
//  ViewController.swift
//  LLLocationDemo-Swift
//
//  Created by lijunliang on 2017/12/5.
//  Copyright © 2017年 Kila. All rights reserved.
//

import UIKit
import LLLocation
import CoreLocation

class ViewController: UIViewController {
    var array:ArrayPorxy<Int> = ArrayPorxy<Int>.init()
    let manager = LLLocationManager.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager.start()
        
        DispatchQueue.global().async {
            while(true){
                sleep(10)
                LocationShareModel.shareModel.locations.forEach(body: { (offset:Int,item:CLLocation) in
                    let fmt = DateFormatter.init()
                    fmt.dateFormat = "HH:mm:ss"
                    var urlReq = URLRequest.init(url: URL.init(string: "http://169.254.235.175:3001?time=\(fmt.string(from: item.timestamp))")!);
                    urlReq.httpMethod = "GET";
//                    urlReq.httpBody = item.description.data(using: String.Encoding.utf8);
                    URLSession.shared.dataTask(with: urlReq, completionHandler: { (data, res, err) in
                        print(err?.localizedDescription);
                    }).resume()
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

