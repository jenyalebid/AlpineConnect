//
//  Postgres.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 2/9/23.
//

import Foundation
import PostgresClientKit

public extension Optional where Wrapped == UUID {
    
    func toPostgres() -> String {
        return self != nil ? "'\(self!.uuidString)'" : "NULL"
    }
}

//public extension Optional where Wrapped == Int {
//
//    func toPostgres() -> String {
//        return self != nil ? "\(self!)" : "NULL"
//    }
//}
//
//public extension Optional where Wrapped == Int32 {
//
//    func toPostgres() -> String {
//        return self != nil ? "\(self!)" : "NULL"
//    }
//}

public extension Optional where Wrapped == String {
    
    func geometryToPostgres() -> String {
//        self != nil && self != "" ? "ST_AsText(ST_GeomFromText('\(self!)',26710))" : "NULL"
        self != nil && self != "" ? "'\(self!)'" : "NULL"
    }
    
    func toPostgres() -> String {
        self != nil && self != "" ? "'\(self!.postgresEscaped)'" : "NULL"
    }
}

public extension Optional where Wrapped == NSNumber {
    
    func toPostgres(isOptional: Bool) -> String {
        if let self {
            return self == 1 ? "TRUE" : "FALSE"
        }
        else {
            return isOptional ? "NULL" : "FALSE"
        }
    }
}

public extension Optional where Wrapped == Date {
    
    func toPostgres() -> String {
        self != nil ? "'\(self!.toPostgresTimestamp())'" : "NULL"
    }
}

public extension Optional where Wrapped == Data {
    func toPostgres() -> String {
        self != nil ? "'\(PostgresByteA(data: self!).postgresValue)'" : "NULL"
    }
}

private extension Date {
    
    func toPostgresTimestamp() -> String {
        toStringTimeZonePST(dateFormat: "yyyy-MM-dd HH:mm:ss")
    }
    
    func toStringTimeZonePST(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        return dateFormatter.string(from: self)
    }
}
