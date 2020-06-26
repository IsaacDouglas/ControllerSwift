//
//  HTTPResponse.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectHTTP

public extension HTTPResponse {
    func sendJSON<T: Encodable>(_ json: T, status: HTTPResponseStatus = .ok) {
        do {
            try setBody(json: json)
                .setHeader(.contentType, value: "application/json")
                .completed(status: status)
        } catch {
            Log("\(error)")
            completed(status: .internalServerError)
        }
    }
}
