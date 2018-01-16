//
//  ArrayProxy.swift
//  LLLocation
//
//  Created by lijunliang on 2018/1/12.
//  Copyright © 2018年 Kila. All rights reserved.
//

import UIKit

public class ArrayPorxy<T>{
    private var array:Array<T> = []
    private let concurrentArrayQueue = DispatchQueue.init(label: "kila.lbs.LLLocation.arrayQueue", attributes:DispatchQueue.Attributes.concurrent)
    public init() {}
    
    public func last(body: @escaping (_ element: T?) -> Void) {
        let read = DispatchWorkItem.init {[weak self] in
            body(self?.array.last)
        }
        concurrentArrayQueue.async(execute: read);
    }
    
    public var last:T? {
        return array.last;
    }
    
    /// write a element
    ///
    /// - Parameter newElement: element
    public func append(_ newElement: T) {
        let write = DispatchWorkItem.init(flags: DispatchWorkItemFlags.barrier, block: {[weak self] in
            self?.array.append(newElement);
        })
        concurrentArrayQueue.async(execute: write);
    }
    
    
    /// read element list
    ///
    /// - Parameters:
    ///   - clear: after finish  if removeAll element from list
    ///   - body: block of offset and element
    public func forEach(clear:Bool = true, body: @escaping ((offset: Int, element: T)) -> Void) {
        let read = DispatchWorkItem.init {[weak self] in
            self?.array.enumerated().forEach({ (args:(offset:Int,element:T)) in
                let (index,item) = args;
                body((offset:index,element:item));
            })
            if(clear){
                self?.array.removeAll();
            }
        }
        concurrentArrayQueue.async(execute: read);
    }
}
