
//  CDObject.swift
//  AlpineConnect
//
//  Created by mkv on 2/21/23.
//

import CoreData


//public protocol CDObject: NSManagedObject, Nameable {
public protocol CDObject where Self: NSManagedObject {
    var guid: UUID { get }
}


public extension CDObject {
    
    var guid: UUID {
        self.managedObjectContext!.performAndWait {
            return value(forKey: "guid") as! UUID
        }
    }
    
    static func clear(in context: NSManagedObjectContext) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Self.entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        let deleteResult = try context.execute(request) as? NSBatchDeleteResult
         
        if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [context])
        }
    }
    
    static var type: CDObject.Type {
        self as CDObject.Type
    }
}

public func printObject(_ obj: CDObject) {
    print(" - object: \(obj.entityDisplayName) ID: \(obj.objectID.uriRepresentation().lastPathComponent) \(obj.guid)")
}
