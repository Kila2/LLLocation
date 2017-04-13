//
//  ArrayProxy.swift
//  LLLocation
//
//  Created by junlianglee on 2017/4/13.
//  Copyright © 2017年 Kila. All rights reserved.
//

import Foundation

public typealias AppendBlock = (Any)->Void

public struct ArrayProxy<T> {
    var array: [T] = []
    public var appendBlock:AppendBlock?
    public mutating func setAppendBlock(appendBlock:@escaping AppendBlock) {
        self.appendBlock = appendBlock
    }
    
    public mutating func append(_ newElement: T, unsave:Bool = false) {
        if appendBlock != nil {
            appendBlock!(newElement)
        }
        
        if !unsave {
            self.array.append(newElement)
        }
        
        print("Element added")
    }
    
    public mutating func remove(at index: Int) {
        print("Removed object \(self.array[index]) at index \(index)")
        self.array.remove(at: index)
    }
    
    public subscript(index: Int) -> T {
        set {
            print("Set object from \(self.array[index]) to \(newValue) at index \(index)")
            self.array[index] = newValue
        }
        get {
            return self.array[index]
        }
    }
}
