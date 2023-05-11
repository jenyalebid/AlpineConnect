//
//  Exportable.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 2/17/23.
//

import CoreData
import PostgresClientKit

public protocol Exportable: Syncable {
    
    associatedtype Object: Exportable
    
    static func insertQuery(for objects: [Object], in context: NSManagedObjectContext) -> String
    static func insertQuery2(for objects: [Object], in context: NSManagedObjectContext) -> String
    
    static func getAllExportable(in context: NSManagedObjectContext) -> [Object]
    static func modifyExportable(_ objects: [Object])
    static func additionalActionsAfterExport()
    static func export(with connection: Connection, in context: NSManagedObjectContext) -> Bool
    
    func checkMissingRequirements() -> Bool
}

public extension Exportable {
    static var exportable: any Exportable.Type {
        self as any Exportable.Type
    }
    
    static func insertQuery2(for objects: [Self], in context: NSManagedObjectContext) -> String {
        ""
    }
}

public extension Exportable {
    
    static func export(with connection: Connection, in context: NSManagedObjectContext) -> Bool {
        let objects = Object.getAllExportable(in: context)
        SyncTracker.shared.makeRecord(name: Object.entityDisplayName, type: .export, recordCount: objects.count)

        guard objects.count > 0 else {
            return true
        }
        var result = false

        defer { Sync.currentQuery = "" }
        do {
            let query1 = Object.insertQuery(for: objects, in: context)
            Sync.currentQuery = query1
            print(query1)
            let statement = try connection.prepareStatement(text: query1)
            defer { statement.close() }
            try statement.execute()
            
            let query2 = Object.insertQuery2(for: objects, in: context)
            if !query2.isEmpty {
                Sync.currentQuery = query2
                print(query2)
                let statement2 = try connection.prepareStatement(text: query2)
                defer { statement2.close() }
                try statement2.execute()
            }
            Sync.currentQuery = ""
            
            Object.modifyExportable(objects)
            Object.additionalActionsAfterExport()

            SyncTracker.shared.endRecordSync()
            result = true

        } catch {
            AppControl.makeError(onAction: "\(Object.entityName) Export", error: error, customDescription: Sync.currentQuery)
        }

        return result
    }
    
    static func getAllExportable(in context: NSManagedObjectContext) -> [Self] {
        Self.findObjects(by: NSPredicate(format: "a_changed = true"), in: context) as? [Self] ?? []
    }
    
    static func modifyExportable(_ objects: [Self]) {
        for object in objects {
            object.setValue(false, forKey: "a_changed")
        }
    }
    
    static func additionalActionsAfterExport() {}
}
