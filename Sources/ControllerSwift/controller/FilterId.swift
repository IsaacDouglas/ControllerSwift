//
//  FilterId.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public class FilterId: Codable {
    public var id: [Int]
    
    public init(id: [Int]) {
        self.id = id
    }
}
