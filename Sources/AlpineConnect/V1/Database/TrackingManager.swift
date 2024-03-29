//
//  TrackingManager.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 4/6/22.
//

import Foundation
import PostgresClientKit

public struct TrackerConnectionInfo {
    
    static var shared = TrackerConnectionInfo()
    
    var host: String = "alpine-database-1.cz1ugaicrz33.us-west-1.rds.amazonaws.com"
    var database: String = "iOS_maintenance"
    var user = "ios_maintenance"
    var password = ""
}

public class TrackingManager {
    
    static public let shared = TrackingManager()
    
    public var pool: ConnectionPool?
    
    public init() {
        let ci = TrackerConnectionInfo.shared
        
        var connectionPoolConfiguration = ConnectionPoolConfiguration()
        connectionPoolConfiguration.maximumConnections = 10
        connectionPoolConfiguration.maximumPendingRequests = 60
        connectionPoolConfiguration.pendingRequestTimeout = nil
        connectionPoolConfiguration.allocatedConnectionTimeout = nil
        connectionPoolConfiguration.dispatchQueue = DispatchQueue.global()
        connectionPoolConfiguration.metricsResetWhenLogged = false
        
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = ci.host
        configuration.database = ci.database
        configuration.user = ci.user
        configuration.credential = .md5Password(password: ci.password)
        configuration.applicationName = "AlpineConnect"
        pool = ConnectionPool(
                   connectionPoolConfiguration: connectionPoolConfiguration,
                   connectionConfiguration: configuration)
    }
}
