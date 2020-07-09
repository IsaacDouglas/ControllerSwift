//
//  Sort.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public enum CSOrderType: String, Codable {
    case ASC
    case DESC
}

public struct CSSort: Codable {
    public let field: String
    public let order: CSOrderType
}
