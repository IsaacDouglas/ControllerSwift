//
//  Token.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectCrypto

public class CSToken: Codable {
    public var token: String
    
    public static var secret: String = "secret"
    public static var algorithm: JWT.Alg = .hs256
    
    public init<T: CSPayloadProtocol>(payload: T) throws {
        let jwt1 = try JWTCreator(payload: payload)
        self.token = try jwt1.sign(alg: CSToken.algorithm, key: CSToken.secret)
    }
    
    public static func verify<T: CSPayloadProtocol>(token: String, on type: T.Type) throws -> T {
        let bearer = token.replacingOccurrences(of: "Bearer ", with: "")
        
        guard let jwt = JWTVerifier(bearer) else {
            throw CSError.genericError("Erro ao inicializar o JWTVerifier")
        }
        
        try jwt.verify(algo: CSToken.algorithm, key: HMACKey(CSToken.secret))
        return try jwt.decode(as: T.self)
    }
}
