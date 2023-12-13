//
//  Syncable.swift
//  AlpineConnect
//
//  Created by mkv on 2/6/23.
//

import CoreData
import AlpineCore
import PostgresClientKit

public protocol Syncable: CDObject {
 
    static var isImportable: Bool { get }
    static var isExportable: Bool { get }
    
    static var syncManager: SyncManager { get }
    
    var isLocal: Bool { get }
}

public extension Syncable {
    
    static var isImportable: Bool {
        self as? Importable.Type != nil
    }
    
    static var isExportable: Bool {
        self as? any Exportable.Type != nil
    }
    
    var isLocal: Bool {
        return value(forKey: "a_syncDate") == nil
    }
}