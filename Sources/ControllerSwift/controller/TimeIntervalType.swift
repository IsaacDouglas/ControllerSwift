//
//  TimeIntervalType.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public enum TimeIntervalType<T: Numeric> {
    case seconds(T)
    case minutes(T)
    case hour(T)
    
    public var totalSeconds: T {
        switch self {
        case .seconds(let time):
            return time
        case .minutes(let time):
            return time * 60
        case .hour(let time):
            return time * 60 * 60
        }
    }
}
