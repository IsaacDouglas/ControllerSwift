//
//  Range.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public struct Range: Codable {
    public let start: Int
    public let end: Int
    
    public var offset: Int { return self.start }
    public var limit: Int { return self.end - self.start }
}
