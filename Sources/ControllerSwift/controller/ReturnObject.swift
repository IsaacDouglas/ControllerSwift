//
//  ReturnObject.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public class ReturnObject<T: Codable>: Codable {
    public var success: Bool
    public var message: String?
    public var token: String?
    public var object: T?
    
    public init(success: Bool, message: String? = nil, token: String? = nil, object: T? = nil) {
        self.success = success
        self.message = message
        self.token = token
        self.object = object
    }
}
