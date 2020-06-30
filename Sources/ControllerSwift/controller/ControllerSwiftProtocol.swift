//
//  ControllerSwift.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation
import PerfectHTTP
import PerfectCRUD

public func Log(_ format: String, function: String = #function, line: Int = #line, file: String = #file) {
    NSLog("function:\(function), line:\(line) <--> \(format)")
}

public protocol ControllerSwiftProtocol where Self: Codable {
    var id: Int { get }
    
    static var uri: String { get }
    
    static func createTable<T: DatabaseConfigurationProtocol>(database: Database<T>) throws
    
    static func getList<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, sort: Sort?, range: Range?, filter: [String: Any]?) throws -> ([Self], Int)
    static func getOne<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self?
    
    static func create<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self?
    
    static func update<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, record: Self) throws -> Self?
    static func updateMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: FilterId, records: [Self]) throws -> [Int]?
    
    static func delete<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, id: Int) throws -> Self?
    static func deleteMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: FilterId) throws -> [Int]?
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

    static func deleteMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: FilterId) throws -> [Int]? {
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
    
    static func updateMany<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, filter: FilterId, records: [Self]) throws -> [Int]? {
        let table = database.table(Self.self)
        
        try database.transaction {
            for record in records {
                let query = table.where(\Self.id == record.id)
                try query.update(record)
            }
        }
        return records.map({ $0.id })
    }
    
    static func getList<T: DatabaseConfigurationProtocol>(database: Database<T>, request: HTTPRequest, response: HTTPResponse, sort: Sort?, range: Range?, filter: [String: Any]?) throws -> ([Self], Int) {
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
    
    static func routes<T: DatabaseConfigurationProtocol>(database: Database<T>) -> [Route] {
        return self.routes(database: database, authenticate: nil)
    }
    
    static func routes<T: DatabaseConfigurationProtocol, U: PayloadProtocol>(database: Database<T>, useAuthenticationWith payloadType: U.Type) -> [Route] {
        return self.routes(database: database, authenticate: { request in
            let payload = try request.payload(on: payloadType)
            if !payload.isAuthenticated {
                throw CSError.genericError("Usuário não autenticado")
            }
            return try Token(payload: payload.reload()).token
        })
    }
    
    private static func routes<T: DatabaseConfigurationProtocol>(database: Database<T>, authenticate: ((HTTPRequest) throws -> String?)?) -> [Route] {
        
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
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                do {
                    guard let id = request.getId() else {
                        response.completed(status: .internalServerError)
                        return
                    }
                    
                    let retorno = try self.getOne(database: database, request: request, response: response, id: id)
                    
                    try response
                        .setBody(json: ReturnObject<Self>(message: "ok", token: token, object: retorno))
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .get, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                let sort = request.param(name: "sort")?.decoder(Sort.self)
                let range = request.param(name: "range")?.decoder(Range.self)
                let filter = request.param(name: "filter")?.convertToDictionary
                
                do {
                    let (retorno, total) = try self.getList(database: database, request: request, response: response, sort: sort, range: range, filter: filter)
                    
                    try response
                        .setBody(json: ReturnObject<[Self]>(message: "ok", token: token, object: retorno))
                        .addHeader(.custom(name: "Access-Control-Expose-Headers"), value: "Content-Range")
                        .setHeader(.contentRange, value: "\(total)")
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .post, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let record = request.getBodyJSON(Self.self) else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let object = try self.create(database: database, request: request, response: response, record: record)
                    
                    if let object = object {
                        try response
                            .setBody(json: ReturnObject<Self>(message: "ok", token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .ok)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .put, uri: "\(self.uri)/{id}", handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let record = request.getBodyJSON(Self.self) else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let object = try self.update(database: database, request: request, response: response, record: record)
                    
                    if let object = object {
                        try response
                            .setBody(json: ReturnObject<Self>(message: "ok", token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .put, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard
                    let filter = request.param(name: "filter")?.decoder(FilterId.self),
                    let records = request.getBodyJSON([Self].self)
                    else {
                        response.completed(status: .internalServerError)
                        return
                }
                
                do {
                    let ids = try self.updateMany(database: database, request: request, response: response, filter: filter, records: records)
                    
                    if let ids = ids {
                        try response
                            .setBody(json: ReturnObject<[Int]>(message: "ok", token: token, object: ids))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .delete, uri: "\(self.uri)/{id}", handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard let id = request.getId() else {
                    response.completed(status: .internalServerError)
                    return
                }
                
                do {
                    let object = try self.delete(database: database, request: request, response: response, id: id)
                    
                    if let object = object {
                        try response
                            .setBody(json: ReturnObject<Self>(message: "ok", token: token, object: object))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .ok)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            routes.append(Route(method: .delete, uri: self.uri, handler: { request, response in
                
                var token: String?
                do {
                    token = try authenticate?(request)
                } catch {
                    Log("\(error)")
                    response.completed(status: .unauthorized)
                    return
                }
                
                guard
                    let filter = request.param(name: "filter")?.decoder(FilterId.self)
                    else {
                        response.completed(status: .internalServerError)
                        return
                }
                
                do {
                    let ids = try self.deleteMany(database: database, request: request, response: response, filter: filter)
                    
                    if let ids = ids {
                        try response
                            .setBody(json: ReturnObject<[Int]>(message: "ok", token: token, object: ids))
                            .setHeader(.contentType, value: "application/json")
                            .completed(status: .created)
                    } else {
                        response.completed(status: .internalServerError)
                    }
                } catch {
                    Log("\(error)")
                    response.completed(status: .internalServerError)
                }
            }))
            
            return routes
        }
}
