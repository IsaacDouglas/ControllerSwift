//
//  String.swift
//  ControllerSwift
//
//  Created by Isaac Douglas on 25/06/20.
//

import Foundation

extension String {
    func decoder<T: Decodable>(_ type: T.Type) -> T? {
        let data = Data(self.utf8)
        return try? JSONDecoder().decode(type, from: data)
    }
    
    var convertToDictionary: [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
            } catch {
                Log("\(error)")
            }
        }
        return nil
    }
    
    var date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: self)
    }
    
    var sha256: String {
        let encoded = digest(.sha256)
        let hexBytes = encoded?.map({ String(format: "%02hhx", $0) })
        return hexBytes!.joined()
    }
}
