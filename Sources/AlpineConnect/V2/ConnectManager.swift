//
//  ConnectManager.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 12/6/23.
//

import Foundation
import AlpineCore

public class ConnectManager: ObservableObject {
    
    public static var shared = ConnectManager()
    
    var isConnected: Bool {
        NetworkMonitor.shared.connected
    }
        
    @Published var user: ConnectUser?
    @Published public var token: Token?
    
    @Published var isSignedIn = false
    
    private var loginData: CredentialsData!
    private var loginInfo: LoginConnectionInfo!
    
    private var postgresInfo: PostgresInfo?
    var isPostgresEnabled: Bool {
        postgresInfo != nil
    }
    
    init() {
        NetworkMonitor.shared.start()
    }
}

extension ConnectManager {
    
    func fillData(email: String, password: String, and info: LoginConnectionInfo) {
        loginData = CredentialsData(email: email, password: password)
        loginInfo = info
        postgresInfo = info.postgresInfo
    }
    
    func attemptLogin(offline: Bool) async throws -> ConnectionResponse {
        guard await NetworkMonitor.shared.canConnectToServer() else {
            return ConnectionResponse(result: .moreDetail, detail: .timeout)
        }
        guard loginData != nil, loginInfo != nil else {
            return ConnectionResponse(result: .fail, problem: ConnectionProblem.missingInfo())
        }
        
        if isConnected && !offline {
            return try await attemptOnlineLogin()
        }
        else {
            return await attemptOfflineLogin()
        }
    }
    
    func attemptOnlineLogin() async throws -> ConnectionResponse {
        let response = try await BackyardLogin(loginInfo, data: loginData).attemptLogin()
        if let data = response.backyardData {
            return try await processBackyardData(data)
        }
        else {
            return response
        }
    }
    
    private func processBackyardData(_ data: BackyardLogin.Response) async throws -> ConnectionResponse {
        createToken(from: data.sessionToken)
        if let lastLogin = UserDefaults.standard.string(forKey: "AC_last_login") {
            if lastLogin != loginData.email {
                return ConnectionResponse(result: .moreDetail, detail: .overrideKeychain)
            }
        }
        return AuthManager(credentials: loginData).attemptToSave()
    }
    
    func attemptOfflineLogin() async -> ConnectionResponse {
        fatalError()
    }
}

extension ConnectManager {
    
    var credentialsExist: Bool {
        UserDefaults.standard.string(forKey: "AC_last_login") != nil
    }
    
    public func getStoredToken() -> Token? {
        if let tokenData = UserDefaults.standard.value(forKey: "AC_backyard_token") as? Data {
            return try? JSONDecoder().decode(Token.self, from: tokenData)
        }
        
        return nil
    }
    
    func requestNewToken(with info: LoginConnectionInfo, and credentials: CredentialsData) async throws -> (response: TokenResponse, token: Token?) {
        guard credentialsExist else { return (TokenResponse.noStoredCredentials, nil) }
        guard isConnected, await NetworkMonitor.shared.canConnectToServer() else { return (TokenResponse.notConnected, nil) }
        
        let response = try await BackyardLogin(info, data: credentials).attemptLogin()
        if let data = response.backyardData {
            createToken(from: data.sessionToken)
            return (TokenResponse.success, getStoredToken())
        }
        if let problem = response.problem {
            return (TokenResponse.serverIssue(problem.detail ?? "No details provided."), nil)
        }
        
        return (TokenResponse.unknownIssue, nil)
    }
    
    func createToken(from value: String) {
        DispatchQueue.main.async { [self] in
            let expDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())!
            token = Token(rawValue: value, expirationDate: expDate)
            UserDefaults.standard.setValue(token?.encoded, forKey: "AC_backyard_token")
        }
    }
    
    func checkForBiometrics() -> ConnectionResponse {
        guard !UserDefaults.standard.bool(forKey: "AC_biometrics_enabled") else {
            return ConnectionResponse(result: .success)
        }
        
        if let lastAskDate = UserDefaults.standard.value(forKey: "AC_last_keychain_ask_date") as? Date {
            if !Date().isNumberOfDays(3, since: lastAskDate) {
                return ConnectionResponse(result: .success)
            }
        }
        return ConnectionResponse(result: .moreDetail, detail: .enableKeychain)
    }
}

extension ConnectManager {
    
    func overrideCredentials() -> ConnectionResponse {
        AuthManager(credentials: loginData).attemptToSave()
    }
}


public extension ConnectManager {
    
    static var isAbleToGetToken: Bool {
        ConnectManager.shared.credentialsExist
    }
    
    static func getValidToken(with info: LoginConnectionInfo) async throws -> (TokenResponse, Token?) {
        guard let email = UserDefaults.standard.string(forKey: "AC_last_login"),
              let password = AuthManager.retrieveFromKeychain(account: email)
        else {
            return (TokenResponse.noStoredCredentials, nil)
        }
        
        if let token = ConnectManager.shared.token ?? ConnectManager.shared.getStoredToken() {
            if token.expirationDate.add(.hour, value: -1) > Date() {
                return (TokenResponse.success, token)
            }
        }

        let credentials = CredentialsData(email: email, password: password)
        return try await ConnectManager.shared.requestNewToken(with: info, and: credentials)
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return decoder
    }
}