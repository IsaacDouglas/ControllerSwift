//
//  PayloadProtocol.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public protocol CSPayloadProtocol: Codable {
    var exp: CLong { get set }
    var iat: CLong { get set }
    
    func reload() -> Self
}

public extension CSPayloadProtocol {
    var isAuthenticated: Bool {
        let timeInterval = Date.timeInterval
        return (self.exp - timeInterval) >= 0
    }
}
