//
//  ConnectUser.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 1/18/24.
//

import Foundation
import Observation

@Observable
public class ConnectUser {
    
    private var data: [String: Any]
    
    public var email: String
    
    internal init(for serverUser: ServerUserResponse) { // user is created on login and should not be initialized elsewhere.
        self.email = serverUser.email
        data = Dictionary.getFromDefaults(key: serverUser.email) ?? Self.makeUser(for: serverUser)
    }
    
    public func save() {
        data.saveToDefaults(key: email)
    }
    
    public func setValue(_ value: Any?, for key: String) {
        data[key] = value
        save()
    }
    
    public func value(for key: String) -> Any? {
        data[key]
    }
}

public extension ConnectUser {
    
    var guid: UUID {
        let id = data["guid"] as? String ?? "00000000-0000-0000-0000-000000000000"
        return UUID(uuidString: id)!
    }
    
    var lastSync: Date? {
        data["last_sync"] as? Date
    }
    
    var fullName: String {
        let first = data["first_name"] as? String ?? "No First Name"
        let last = data["last_name"] as? String ?? "No Last Name"
        
        return first + " " + last
    }
}

private extension ConnectUser {
    
    static func makeUser(for serverUser: ServerUserResponse) -> [String: Any] {
        var data = [String: Any]()
        data["email"] = serverUser.email
        data["first_name"] = serverUser.firstName
        data["last_name"] = serverUser.lastName
        data["is_admin"] = serverUser.isAdmin
        
        data.saveToDefaults(key: serverUser.email)
        return data
    }
}
