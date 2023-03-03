//
//  Exportable.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 2/17/23.
//

import CoreData
import PostgresClientKit

public protocol Exportable: Syncable {
    
    static func insertQuery(for objects: [Self], in context: NSManagedObjectContext) -> String
    static func insertQuery2(for objects: [Self], in context: NSManagedObjectContext) -> String
    
    static func getAllExportable(in context: NSManagedObjectContext) -> [Self]
    static func modifyExportable(_ objects: [Self])
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
        let objects = Self.getAllExportable(in: context)
        SyncTracker.shared.makeRecord(name: Self.entityDisplayName, type: .export, recordCount: objects.count)

        guard objects.count > 0 else {
            return true
        }
        var result = false

        do {
            let query1 = Self.insertQuery(for: objects, in: context)
            print(query1)
            let statement = try connection.prepareStatement(text: query1)
            defer { statement.close() }
            try statement.execute()
            
            let query2 = Self.insertQuery2(for: objects, in: context)
            if !query2.isEmpty {
                print(query2)
                let statement2 = try connection.prepareStatement(text: query2)
                defer { statement2.close() }
                try statement2.execute()
            }
            
            Self.modifyExportable(objects)
            Self.additionalActionsAfterExport()
            try context.save()

            SyncTracker.shared.endRecordSync()
            result = true

        } catch {
            AppControl.makeError(onAction: "\(Self.entityName) Export", error: error)
        }

        return result
    }
    
    static func getAllExportable(in context: NSManagedObjectContext) -> [Self] {
        Self.findObjects(by: NSPredicate(format: "changed_ = true"), in: context) as? [Self] ?? []
    }
    
    static func modifyExportable(_ objects: [Self]) {
        for object in objects {
            object.setValue(false, forKey: "changed_")
        }
    }
    
    static func additionalActionsAfterExport() {}
}
