//
//  LocationManagerError.swift
//  LLLocation
//
//  Created by lijunliang on 2018/1/18.
//  Copyright © 2018年 Kila. All rights reserved.
//

import UIKit

internal struct LocationManagerError: Error {
    enum ErrorKind {
        case LocationFailed
    }
    let kind: ErrorKind
}
