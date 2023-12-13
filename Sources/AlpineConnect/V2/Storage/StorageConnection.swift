//
//  StorageConnection.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 12/7/23.
//

import Foundation
import SwiftData

@Observable
public class StorageConnection {
    
    var manager: StorageManager {
        StorageManager.shared
    }
    
    public var sessionToken: Token?
    public var items = [StorageItem]()
    
    public var alert: ConnectAlert = .empty
    public var isAlertPresented = false
    
    public var lastUpdate: Date?
    
    public var status: StorageConnectionStatus
    public var refreshID = UUID()
        
    public var localPath: String
    public var serverPath: String?
    
    public var isConnected: Bool {
        NetworkMonitor.shared.connected
    }
    
    public var isAbleToFetch: Bool {
        sessionToken != nil && isConnected && status == .readyToFetch
    }
    
    public init(sessionToken: Token?, status: StorageConnectionStatus, localPath: String, serverPath: String? = nil) {
        self.sessionToken = sessionToken
        self.status = status
        self.localPath = localPath
        self.serverPath = serverPath
    }
    
    public func refresh() {
        refreshID = UUID()
    }
    
    func presentAlert(from problem: ConnectionProblem) {
        DispatchQueue.main.async { [self] in
            lastUpdate = Date()
            status = .issue(problem.alertDetail)
            alert = problem.alert
            isAlertPresented.toggle()
        }
    }
}