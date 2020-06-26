//
//  HTTPRequest.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectHTTP

public extension HTTPRequest {
    func getBodyJSON<T: Decodable>(_ type: T.Type) -> T? {
        guard let body = postBodyString else { return nil }
        return body.decoder(type)
    }
    
    func payload<T: PayloadProtocol>(on type: T.Type) throws -> T {
        guard let authorization = header(.authorization) else {
            throw CSError.genericError("Não foi encontrado o \"header authorization\"")
        }
        return try Token.verify(token: authorization, on: type)
    }
    
    func getId() -> Int? {
        guard
            let value = urlVariables["id"],
            let id = Int(value)
            else {
                return nil
        }
        return id
    }
}
