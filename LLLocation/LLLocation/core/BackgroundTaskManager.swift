//
//  BackgroundTaskManager.swift
//  LLLocation
//
//  Created by junlianglee on 2017/1/21.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation


internal extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    internal mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

internal class BackgroundTaskManager {
    private static let TAG = "BackgroundTaskManager"
    internal static let sharedBackgroundTaskManager = BackgroundTaskManager()
    
    private var bgTaskIdList:[UIBackgroundTaskIdentifier]
    private var masterTaskId:UIBackgroundTaskIdentifier;
    
    private init() {
        bgTaskIdList = [];
        masterTaskId = UIBackgroundTaskInvalid
    }
    
    internal func beginNewBackgroundTask() {
        let application = UIApplication.shared
        
        guard application.applicationState == .background else {
            return
        }
        
        var bgTaskId = UIBackgroundTaskInvalid
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(expirationHandler:))) {
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                LLLog.v(BackgroundTaskManager.TAG, "background task \(bgTaskId) expired")
                self.bgTaskIdList.remove(object: bgTaskId)
                application.endBackgroundTask(bgTaskId)
            })
        }
        if self.masterTaskId == UIBackgroundTaskInvalid {
            self.masterTaskId = bgTaskId
            LLLog.v(BackgroundTaskManager.TAG, "started master task \(self.masterTaskId)")
        }
        else {
            LLLog.v(BackgroundTaskManager.TAG, "started background task \(bgTaskId)")
            self.endAllBackgroundTasks()
            self.bgTaskIdList.append(bgTaskId)
        }
    }
    
    internal func endAllBackgroundTasks() {
        drainBGTaskList(all:true)
    }
    
    private func endBackgroundTasks() {
        drainBGTaskList(all: false)
    }
    
    internal func drainBGTaskList(all:Bool) {
        let application = UIApplication.shared
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            var i = all ? 0 : 1
            while i<count {
                let bgTaskId = self.bgTaskIdList.first
                if let bgTaskId = bgTaskId{
                    LLLog.v(BackgroundTaskManager.TAG, "ending background task with id \(bgTaskId)")
                    application.endBackgroundTask(bgTaskId)
                }
                self.bgTaskIdList.removeFirst()
                i+=1
            }
            if self.bgTaskIdList.count > 0 {
                LLLog.v(BackgroundTaskManager.TAG, "kept background taks id \(self.bgTaskIdList.first!)")
            }
            if all {
                LLLog.v(BackgroundTaskManager.TAG, "no more background tasks running")
                application .endBackgroundTask(self.masterTaskId)
                self.masterTaskId = UIBackgroundTaskInvalid
            }
            else {
                LLLog.v(BackgroundTaskManager.TAG, "kept master background task id \(self.masterTaskId)")
            }
            
        }
    }
}
