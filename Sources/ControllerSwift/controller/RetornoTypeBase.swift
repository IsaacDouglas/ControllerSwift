//
//  RetornoTypeBase.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

// MARK: - RetornoTypeBase
public protocol RetornoTypeBase: class, Codable {
    var message: String { get set }
    var token: String? { get set }
}

// MARK: - RetornoSimple
public class RetornoSimple: RetornoTypeBase {
    public var message: String
    public var token: String?
    
    public init(message: String, token: String? = nil) {
        self.message = message
        self.token = token
    }
}

// MARK: - RetornoObject
class RetornoObject<T: Codable>: RetornoTypeBase {
    public var message: String
    public var token: String?
    public var object: T?
    
    public init(message: String, token: String? = nil, object: T? = nil) {
        self.message = message
        self.token = token
        self.object = object
    }
}
