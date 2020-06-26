//
//  ReturnObject.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public class ReturnObject<T: Codable>: Codable {
    public var message: String
    public var token: String?
    public var object: T?
    
    public init(message: String, token: String? = nil, object: T? = nil) {
        self.message = message
        self.token = token
        self.object = object
    }
}
