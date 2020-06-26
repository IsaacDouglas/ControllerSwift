//
//  Token.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectCrypto

public class Token: Codable {
    public var token: String
    
    public static var secret: String = "secret"
    public static var algorithm: JWT.Alg = .hs256
    
    public init<T: PayloadProtocol>(payload: T) throws {
        let jwt1 = try JWTCreator(payload: payload)
        self.token = try jwt1.sign(alg: Token.algorithm, key: Token.secret)
    }
    
    public static func verify<T: PayloadProtocol>(token: String, on type: T.Type) throws -> T {
        let bearer = token.replacingOccurrences(of: "Bearer ", with: "")
        
        guard let jwt = JWTVerifier(bearer) else {
            throw CSError.genericError("Erro ao inicializar o JWTVerifier")
        }
        
        try jwt.verify(algo: Token.algorithm, key: HMACKey(Token.secret))
        return try jwt.decode(as: T.self)
    }
}
