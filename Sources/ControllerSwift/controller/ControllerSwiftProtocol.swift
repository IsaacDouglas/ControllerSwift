//
//  ControllerSwift.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectHTTP
import PerfectCRUD

public func CSLog(_ format: String, function: String = #function, line: Int = #line, file: String = #file) {
    NSLog("function:\(function), line:\(line) <--> \(format)")
}

public protocol ControllerSwiftProtocol where Self: Codable {
    var id: Int { get }
    
    static var uri: String { get }
    
    static func createTable<T: DatabaseConfigurationProtocol>(database: Database<T>) throws
    
    static func getList<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, sort: CSSort?, range: CSRange?, filter: [String: Any]?) throws -> ([Self], Int)
    static func getOne<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self?
    
    static func create<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self?
    
    static func update<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self?
    static func updateMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: CSFilterId, records: [Self]) throws -> [Int]?
    
    static func delete<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self?
    static func deleteMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: CSFilterId) throws -> [Int]?
}

public extension ControllerSwiftProtocol {
    static var uri: String {
        return "/\(String(describing: self).lowercased())"
    }
    
    static func createTable<T: DatabaseConfigurationProtocol>(database: Database<T>) throws {
        try database.create(Self.self, policy: .dropTable)
    }
    
    static func create<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self? {
        let table = database.table(Self.self)
        
        var item: Self?
        try database.transaction {
            if record.id > 0 {
                try table.insert(record)
            } else {
                try table.insert(record, ignoreKeys: \Self.id)
            }
            item = try table.limit(1, skip: 0).order(descending: \Self.id).first()
        }
        return item
    }

    static func deleteMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: CSFilterId) throws -> [Int]? {
        let table = database.table(Self.self)
        try table.where(\Self.id ~ filter.id).delete()
        return filter.id
    }

    static func delete<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self? {
        let table = database.table(Self.self)
        let query = table.where(\Self.id == id)
        let first = try query.first()
        try query.delete()
        return first
    }

    static func getOne<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self? {
        let table = database.table(Self.self)
        return try table.where(\Self.id == id).first()
    }
    
    static func update<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self? {
        let table = database.table(Self.self)
        try table.where(\Self.id == record.id).update(record)
        return record
    }
    
    static func updateMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: CSFilterId, records: [Self]) throws -> [Int]? {
        let table = database.table(Self.self)
        
        try database.transaction {
            for record in records {
                let query = table.where(\Self.id == record.id)
                try query.update(record)
            }
        }
        return records.map({ $0.id })
    }
    
    static func getList<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, sort: CSSort?, range: CSRange?, filter: [String: Any]?) throws -> ([Self], Int) {
        let count = try database.table(Self.self).count()
        
        var list = [String]()
        
        if let filter = filter {
            if let ids = filter["ids"] as? [Int] {
                let joined = ids.map({ "\($0)" }).joined(separator: ", ")
                list.append("WHERE id IN (\(joined))")
            }
        }
        
        if let sort = sort {
            list.append("ORDER BY \(sort.field) \(sort.order.rawValue)")
        }
        
        if let range = range {
            list.append("LIMIT \(range.limit) OFFSET \(range.offset)")
        }
        
        let select = try database.sql("SELECT * FROM \(Self.CRUDTableName) \(list.joined(separator: " "))", Self.self)
        return (select, count)
    }
}

public extension ControllerSwiftProtocol {
    
    static func routes<T: CSDatabaseProtocol>(databaseType: T.Type) -> [Route] {
        return self.routes(databaseType: databaseType, authenticate: nil)
    }
    
    static func routes<T: CSDatabaseProtocol, U: CSPayloadProtocol>(databaseType: T.Type, useAuthenticationWith payloadType: U.Type) -> [Route] {
        return self.routes(databaseType: databaseType, authenticate: { request in
            let payload = try request.payload(on: payloadType)
            if !payload.isAuthenticated {
                throw CSError.genericError("Usuário não autenticado")
            }
            return try CSToken(payload: payload.reload()).token
        })
    }
    
    private static func routes<T: CSDatabaseProtocol>(databaseType: T.Type, authenticate: ((HTTPRequest) throws -> String?)?) -> [Route] {
        
            var routes = [Route]()
            
            routes.append(Route(method: .options, uri: self.uri, handler: { request, response in
                response.completed(status: .ok)
            }))
            
            routes.append(Route(method: .options, uri: "\(self.uri)/{id}", handler: { request, response in
                response.completed(status: .ok)
            }))
            
            routes.append(Route(method: .get, uri: "\(self.uri)/{id}", handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                do {
                    guard let id = request.getId() else {
                        response.completed(status: .internalServerError)
                        return
                    }
                    
                    let database = try databaseType.init().getDB(reset: false)
                    let object = try self.getOne(database: database, request: request, response: response, id: id)
                    let success = (object != nil)
                    let message = success ? nil : "null"
                    
                    try response
                        .setBody(json: CSReturnObject<Self>(success: success, message: message, token: token, object: object))
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .get, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                let sort = request.param(name: "sort")?.decoder(CSSort.self)
                let range = request.param(name: "range")?.decoder(CSRange.self)
                let filter = request.param(name: "filter")?.convertToDictionary
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let (object, total) = try self.getList(database: database, request: request, response: response, sort: sort, range: range, filter: filter)
                    
                    try response
                        .setBody(json: CSReturnObject<[Self]>(success: true, message: nil, token: token, object: object))
                        .addHeader(.custom(name: "Access-Control-Expose-Headers"), value: "Content-Range")
                        .setHeader(.contentRange, value: "\(total)")
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .post, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let record = request.getBodyJSON(Self.self) else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let object = try self.create(database: database, request: request, response: response, record: record)
                    let success = (object != nil)
                    let message = success ? nil : "null"
                    
                    if let object = object {
                        try response
                            .setBody(json: CSReturnObject<Self>(success: success, message: message, token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .ok)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .put, uri: "\(self.uri)/{id}", handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let record = request.getBodyJSON(Self.self) else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let object = try self.update(database: database, request: request, response: response, record: record)
                    let success = (object != nil)
                    let message = success ? nil : "null"
                    
                    if let object = object {
                        try response
                            .setBody(json: CSReturnObject<Self>(success: success, message: message, token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .put, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard
                    let filter = request.param(name: "filter")?.decoder(CSFilterId.self),
                    let records = request.getBodyJSON([Self].self)
                    else {
                        response.completed(status: .internalServerError)
                        return
                }
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let ids = try self.updateMany(database: database, request: request, response: response, filter: filter, records: records)
                    
                    if let ids = ids {
                        try response
                            .setBody(json: CSReturnObject<[Int]>(success: true, message: nil, token: token, object: ids))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .delete, uri: "\(self.uri)/{id}", handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let id = request.getId() else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let object = try self.delete(database: database, request: request, response: response, id: id)
                    let success = (object != nil)
                    let message = success ? nil : "null"
                    
                    if let object = object {
                        try response
                            .setBody(json: CSReturnObject<Self>(success: success, message: message, token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .ok)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .delete, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard
                    let filter = request.param(name: "filter")?.decoder(CSFilterId.self)
                    else {
                        response.completed(status: .internalServerError)
                        return
                }
                
                do {
                    let database = try databaseType.init().getDB(reset: false)
                    let ids = try self.deleteMany(database: database, request: request, response: response, filter: filter)
                    
                    if let ids = ids {
                        try response
                            .setBody(json: CSReturnObject<[Int]>(success: true, message: nil, token: token, object: ids))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    CSLog("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            return routes
        }
}
