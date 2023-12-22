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
    
    public var status: StorageConnectionStatus = .initial
    public var refreshID = UUID()
        
    public var serverPath: String
    public var localPath: String?
    
    public var reference: ReferenceLocation
    
    public var isConnected: Bool {
        NetworkMonitor.shared.connected
    }

    public var isAbleToFetch: Bool {
        sessionToken != nil && isConnected && status == .readyToFetch
    }
    
    public init(reference: ReferenceLocation, serverPath: String, localPath: String? = nil) {
        self.serverPath = serverPath
        self.localPath = localPath
        self.reference = reference
    }
    
    public func refresh() {
        DispatchQueue.main.async {
            self.refreshID = UUID()
        }
    }
    
    func presentAlert(from problem: ConnectionProblem) {
        DispatchQueue.main.async { [self] in
            lastUpdate = Date()
            status = .issue(problem.alertDetail)
            alert = problem.alert
            isAlertPresented.toggle()
        }
    }
    
   public func presentTimeoutAlert() {
        DispatchQueue.main.async { [self] in
            let issue = ConnectionProblem(title: "Connection Timeout", detail: "Could not establish connection with Cloud in reasonable time.", customAlert: nil)
            status = .offline
            alert = issue.alert
            isAlertPresented.toggle()
        }
    }
    
    public func getToken(with info: LoginConnectionInfo, attemptFetchNew: Bool) async {
        do {
            let response = attemptFetchNew ?
            try await ConnectManager.fetchNewToken(with: info) :
            try await ConnectManager.getValidToken(with: info)
            
            var status = StorageConnectionStatus.initial
            
            switch response.0 {
            case .success:
                status = .initial
            case .noStoredCredentials:
                status = .issue("Missing Login Credentials")
            case .notConnected:
                status = .offline
            case .serverIssue(let description):
                if description == "Session not authorized (Access token is disabled, a newer session exists)" {
                    await getToken(with: info, attemptFetchNew: true)
                }
                status = .issue(description)
            case .unknownIssue:
                status = .issue("Unknown issue occurred while attempting to get token.")
            }
            
            if let token = response.1 {
                self.sessionToken = token
            }
            self.status = status
        }
        catch {
            fatalError()
        }
    }

    
//    static func getStatus(token: Token?) -> StorageConnectionStatus {
//        guard let token else { return .missingToken }
//        if NetworkMonitor.shared.connected, NetworkMonitor.shared.ca
//    }
}
