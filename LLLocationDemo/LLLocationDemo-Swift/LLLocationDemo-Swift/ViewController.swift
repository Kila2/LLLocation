//
//  ViewController.swift
//  LLLocationDemo-Swift
//
//  Created by lijunliang on 2017/12/5.
//  Copyright © 2017年 Kila. All rights reserved.
//

import UIKit
import LLLocation
class ViewController: UIViewController {
    var array:ArrayPorxy<Int> = ArrayPorxy<Int>.init()
    let manager = LLLocationManager.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

