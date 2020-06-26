//
//  Sort.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public enum OrderType: String, Codable {
    case ASC
    case DESC
}

public struct Sort: Codable {
    public let field: String
    public let order: OrderType
}
