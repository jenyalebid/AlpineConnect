//
//  ObjectContainer.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 2/24/23.
//

import CoreData
import AlpineCore


public class ObjectContainer {
    
    public var objects = [CDObject.Type]()
    public var nonClearableObjects = [CDObject.Type]()
    public var importHelperObjects = [ExecutionHelper.Type]()
    public var exportHelperObjects = [ExecutionHelper.Type]()
    
    public var atlasObjects = [AtlasObject.Type]()
    
    public init(objects: [CDObject.Type], nonClearables: [CDObject.Type] = [], importHelpers: [ExecutionHelper.Type] = [], exportHelpers: [ExecutionHelper.Type] = [], atlasObjects: [AtlasSyncable.Type] = []) {
        self.objects = objects
        self.nonClearableObjects = nonClearables
        self.importHelperObjects = importHelpers
        self.exportHelperObjects = exportHelpers
        self.atlasObjects = atlasObjects
    }
}

public class CDObjects {
    
    static public func clearAll(_ objectsContainer: ObjectContainer, in context: NSManagedObjectContext, doAfter: (() -> ())? = nil) async -> Result<Void, Error> {
        await context.perform {
            do {
                for object in objectsContainer.objects {
                    if objectsContainer.nonClearableObjects.contains(where: { $0 == object }) { continue }
                    try object.clear(in: context)
                }
                
                try context.persistentSave()
//                context.reset()
            }
            catch {
                return .failure(error)
            }
            
            if let doAfter {
                doAfter()
            }
            
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(.viewUpdate(with: "reloadSidebar"))
//            }
            return .success(())
        }
    }
    
    static public func fetchObject(as layer: String, with guid: UUID, in context: NSManagedObjectContext) -> CDObject? {
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: layer)
            request.predicate = NSPredicate(format: "a_guid = %@", guid as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            
            var result: CDObject?
            
            do {
                result = try context.fetch(request).first as? CDObject
            }
            catch {
                Core.makeError(error: error, additionalInfo: "Could not find selected feature.")
            }
            
            return result
        }
    }
}

extension ObjectContainer {
    public var atlasSyncableObjects: [AtlasSyncable.Type] {
        objects.filter({ $0 is AtlasSyncable.Type}) as! [AtlasSyncable.Type]
    }
}
