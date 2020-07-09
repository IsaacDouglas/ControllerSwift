//
//  DatabaseProtocol.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 09/07/20.
//

import Foundation
import PerfectCRUD

public protocol CSDatabaseProtocol {
    associatedtype T: DatabaseConfigurationProtocol
    init()
    func getDB(reset: Bool) throws -> Database<T>
}
