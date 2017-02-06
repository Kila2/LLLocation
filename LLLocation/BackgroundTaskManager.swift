//
//  BackgroundTaskManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/21.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation


extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    public mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

public class BackgroundTaskManager {
    static let TAG = "BackgroundTaskManager"
    public static let sharedBackgroundTaskManager = BackgroundTaskManager()
    
    private var bgTaskIdList:[UIBackgroundTaskIdentifier]
    private var masterTaskId:UIBackgroundTaskIdentifier;
    
    private init() {
        bgTaskIdList = [];
        masterTaskId = UIBackgroundTaskInvalid
    }
    
    public func beginNewBackgroundTask() {
        let application = UIApplication.shared
        
        guard application.applicationState == .background else {
            return
        }
        
        var bgTaskId = UIBackgroundTaskInvalid
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(expirationHandler:))) {
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                "background task \(bgTaskId) expired".showOnConsole(BackgroundTaskManager.TAG)
                self.bgTaskIdList.remove(object: bgTaskId)
                application.endBackgroundTask(bgTaskId)
            })
        }
        if self.masterTaskId == UIBackgroundTaskInvalid {
            self.masterTaskId = bgTaskId
            "started master task \(self.masterTaskId)".showOnConsole(BackgroundTaskManager.TAG)
        }
        else {
            "started background task \(bgTaskId)".showOnConsole(BackgroundTaskManager.TAG)
            self.endAllBackgroundTasks()
            self.bgTaskIdList.append(bgTaskId)
        }
    }
    
    public func endAllBackgroundTasks() {
        drainBGTaskList(all:true)
    }
    
    private func endBackgroundTasks() {
        drainBGTaskList(all: false)
    }
    
    func drainBGTaskList(all:Bool) {
        let application = UIApplication.shared
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            var i = all ? 0 : 1
            while i<count {
                let bgTaskId = self.bgTaskIdList.first
                if let bgTaskId = bgTaskId{
                    "ending background task with id \(bgTaskId)".showOnConsole(BackgroundTaskManager.TAG)
                    application.endBackgroundTask(bgTaskId)
                }
                self.bgTaskIdList.removeFirst()
                i+=1
            }
            if self.bgTaskIdList.count > 0 {
                "kept background taks id \(self.bgTaskIdList.first!)".showOnConsole(BackgroundTaskManager.TAG)
            }
            if all {
                "no more background tasks running".showOnConsole(BackgroundTaskManager.TAG)
                application .endBackgroundTask(self.masterTaskId)
                self.masterTaskId = UIBackgroundTaskInvalid
            }
            else {
                "kept master background task id \(self.masterTaskId)".showOnConsole(BackgroundTaskManager.TAG)
            }
            
        }
    }
}
