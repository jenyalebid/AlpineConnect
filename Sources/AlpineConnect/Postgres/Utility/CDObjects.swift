//
//  CDObjects.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 2/24/23.
//

import CoreData

public class CDObjects {
    
    static public var objects = [CDObject.Type]()
    static public var notClearable = [CDObject.Type]()
    
    static public func clearAll(in context: NSManagedObjectContext, doAfter: (() -> ())? = nil) async -> Result<Void, Error> {
        await context.perform {
            do {
                for object in objects {
                    if notClearable.contains(where: { $0 == object }) { continue }
                    try object.clear(in: context)
                }
                
                try context.save()
                context.reset()
            }
            catch {
                return .failure(error)
            }
            
            if let doAfter {
                doAfter()
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("Connect-Refresh"), object: nil)
            }
            return .success(())
        }
    }
    
    static public func fetchObject(as layer: String, with guid: UUID, in context: NSManagedObjectContext) -> CDObject? {
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: layer.appending("_V1"))
            request.predicate = NSPredicate(format: "guid = %@", guid as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            
            var result: CDObject?
            
            do {
                result = try context.fetch(request).first as? CDObject
            }
            catch {
                AppControl.makeError(onAction: "Fetching Feature", error: error, customDescription: "Could not find selected feature.")
            }
            
            return result
        }
    }
}