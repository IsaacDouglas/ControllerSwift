//
//  Payload.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

public class Payload: Codable {
    public static var expirationTime: TimeIntervalType = .minutes(10)
    
    public var sub: Int?    //(subject) = Entidade à quem o token pertence, normalmente o ID do usuário
    public var iss: String? //(issuer) = Emissor do token
    public var exp: CLong   //(expiration) = Timestamp de quando o token irá expirar
    public var iat: CLong   //(issued at) = Timestamp de quando o token foi criado
    public var aud: String? //(audience) = Destinatário do token, representa a aplicação que irá usá-lo
    
    public var name: String
    public var admin: Bool
    public var permissions: [String]
    
    public var isAuthenticated: Bool {
        let timeInterval = Date.timeInterval
        return (self.exp - timeInterval) >= 0
    }
    
    public init(sub: Int? = nil, iss: String? = nil, aud: String? = nil, name: String, admin: Bool, permissions: [String]) {
        self.sub = sub
        self.iss = iss
        self.aud = aud
        self.name = name
        self.admin = admin
        self.permissions = permissions
        
        let timeInterval = Date.timeInterval
        self.exp = timeInterval + Payload.expirationTime.totalSeconds
        self.iat = timeInterval
    }
    
    public func reload() -> Payload {
        return Payload(sub: self.sub, iss: self.iss, aud: self.aud, name: self.name, admin: self.admin, permissions: self.permissions)
    }
}
