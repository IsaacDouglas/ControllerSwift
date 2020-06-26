//
//  HTTPRequest.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectHTTP

extension HTTPRequest {
    func getBodyJSON<T: Decodable>(_ type: T.Type) -> T? {
        guard let body = postBodyString else { return nil }
        return body.decoder(type)
    }
    
    func payload() throws -> Payload {
        guard let authorization = header(.authorization) else {
            throw CSError.genericError("Não foi encontrado o \"header authorization\"")
        }
        return try Token.verify(token: authorization)
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
