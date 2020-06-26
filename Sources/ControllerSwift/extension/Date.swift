//
//  Date.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

extension Date {
    static var timeInterval: CLong {
        return CLong(Date().timeIntervalSince1970.rounded())
    }
    
    var timeInterval: CLong {
        return CLong(timeIntervalSince1970.rounded())
    }
}
