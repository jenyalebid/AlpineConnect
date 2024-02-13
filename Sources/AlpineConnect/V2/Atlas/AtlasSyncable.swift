//
//  AtlasSyncable.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 1/25/24.
//

import CoreData
import AlpineCore

public protocol AtlasSyncable: AtlasObject, Importable {
    
    static var syncBatchSize: Int { get }
    static var syncPredicate: NSPredicate { get }
    
    static var isEditable: Bool { get }
        
    static func performAtlasSynchronization(with data: [AtlasFeatureData], deleting: [UUID]) async throws
    static func createLayerIfNecessary() async throws
    
    static func clearCache() throws
    static func deleteLayer() throws
    
    func updateWithGeometry(_ geometry: String?)
}

public extension AtlasSyncable {
    
    var geometry: String? {
        get {
            self.managedObjectContext?.performAndWait {
                self.value(forKey: "a_geometry") as? String
            }
        }
        set {
            self.managedObjectContext?.performAndWait {
                self.setValue(newValue, forKey: "a_geometry")
            }
        }
    }
    
    func getGeometry(in context: NSManagedObjectContext) -> String? {
        context.performAndWait {
            self.value(forKey: "a_geometry") as? String
        }
    }
}

public extension AtlasSyncable {
    
    static var syncBatchSize: Int {
        100
    }

    static func performAtlasSynchronization(with data: [AtlasFeatureData], deleting: [UUID]) async throws {
        fatalError(#function + " must be implemented in client.")
    }
    
    static var syncPredicate: NSPredicate {
        NSPredicate(format: "a_syncDate > %@", syncManager.tracker.currentSyncStartDate as CVarArg)
    }
}