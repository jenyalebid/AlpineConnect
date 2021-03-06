//
//  AuthenticationViewModel.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 5/6/22.
//

import Security
import LocalAuthentication

final class KeychainAuthentication {
    
    static var shared = KeychainAuthentication()
    
    var userManager = UserManager.shared
    
    var biometricLoginEnabled: Bool = false
    var supportBiometricAuthType: String?
        
    func authenticateUser(info: Login.UserLoginUpdate, completionHandler: @escaping(LoginResponse) -> Void) {
        if NetworkMonitor.shared.connected {
            Login.loginUser(info: info, completionHandler: { response in
                completionHandler(response)
            })
        } else {
            completionHandler(offlineCheck())
        }
    }
    
    func offlineCheck() -> LoginResponse {
        guard Login.getUserFromUserDefaults() else {
            return .networkError
        }
        if userManager.userName == userManager.storedUserName && userManager.password == userManager.storedPassword {
            return .successfulLogin
        }
        if userManager.userName != userManager.storedUserName {
            return .offlineDiffirentUser
        }
        if userManager.userName == userManager.storedUserName && userManager.password != userManager.storedPassword {
            return .wrongPassword
        }
        return .networkError
    }
    
    func saveCredentialsToKeyChain() {
        let userAccount = "AuthenticatedUserInfo"
        let userCredentialsDict: [String: Any] = ["userName": userManager.userName, "password": userManager.password, "biometricLoginEnabled": biometricLoginEnabled]
        let credentialsData: Data = try! NSKeyedArchiver.archivedData(withRootObject: userCredentialsDict, requiringSecureCoding: false)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword as String,
                                    kSecAttrAccount as String: userAccount,
                                    kSecValueData as String: credentialsData]
        SecItemDelete(query as CFDictionary)
        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
        if status == noErr {
            UserDefaults().setValue(true, forKey: "saveCredentialsOnKeychain")
        } else {
            fatalError("Key chain did not save")
        }
    }
    
    func fetchCredentialsFromKeyChain() {
        if UserDefaults().bool(forKey: "saveCredentialsOnKeychain") == false {
            deleteAllKeyChainItems()
            return;
        } else {
            fetchKeyChain()
        }
    }
    
    private func fetchKeyChain() {
        if let dictionaryValues = self.fetchKeyChainValues() {
            self.userManager.userName = dictionaryValues["userName"] as? String ?? ""
            self.userManager.storedUserName = dictionaryValues["userName"] as? String ?? ""
            self.biometricLoginEnabled = dictionaryValues["biometricLoginEnabled"] as? Bool ?? false
            self.userManager.storedPassword = dictionaryValues["password"] as? String ?? ""
        }
    }
    
    func updateCredentialsOnKeyChain(completionHandler: @escaping(Bool) -> ()) {
        let userAccount = "AuthenticatedUserInfo"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: userAccount]
        let updatingUserDataDict: [String: Any] = ["userName": userManager.userName, "password": userManager.password, "biometricLoginEnabled": biometricLoginEnabled]
        let userData: Data = try! NSKeyedArchiver.archivedData(withRootObject: updatingUserDataDict, requiringSecureCoding: false)
        let updatingField: [String: Any] = [kSecAttrAccount as String: userAccount,
                                            kSecValueData as String: userData
        ]
        updateStoredPassword(newPassword: userManager.password)
        let status = SecItemUpdate(query as CFDictionary, updatingField as CFDictionary)
        if status == noErr {
            completionHandler(true);
        } else {
            completionHandler(true);
        }
    }
    
    func updateStoredPassword(newPassword: String) {
        UserManager.shared.storedPassword = newPassword
    }
    
    func areCredentialsSaved() -> Bool {
        return !(self.fetchKeyChainValues() == nil)
    }
    
    func credentialsChanged() -> Bool {
        return ((userManager.storedUserName != userManager.userName) || (userManager.storedPassword != userManager.password))
    }
    
    func deleteAllKeyChainItems() {
        let secItemClasses = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        for itemClass in secItemClasses {
            let spec: NSDictionary = [kSecClass: itemClass]
            SecItemDelete(spec)
        }
    }
    
    private func fetchKeyChainValues() -> [String: Any]? {
        let userAccount = "AuthenticatedUserInfo"
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: userAccount,
                                    kSecReturnData as String: kCFBooleanTrue!,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == noErr {
            if let data = dataTypeRef as? Data {
                do {
                    let dataDict = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Any]
                    return dataDict
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            }
        } else {
            return nil
        }
        return nil
    }
    
    func isBiometricSupportedOnDevice() -> Bool {
        let context = LAContext()
        var contextError: NSError?
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &contextError) {
            if context.biometryType == .faceID || context.biometryType == .touchID {
                self.supportBiometricAuthType = context.biometryType == .faceID ? "FaceID" : "TouchID"
                return true
            } else {
                self.supportBiometricAuthType = nil
                return false
            }
        } else {
            self.supportBiometricAuthType = nil
            return false
        }
    }
    
    func askForBioMetricAuthenticationSetup() -> Bool {
        let alreadyApprovedBioAuth = UserDefaults().bool(forKey: "biometricAuthAuthorized")
        if isBiometricSupportedOnDevice() {
            if alreadyApprovedBioAuth {
                return false
            } else {
                if let lastAskedDate = fetchBiometricAuthRequestTimeFromUserDefault() {
                    let numberOfDays = Date().daysBetweenDates(startDate: lastAskedDate)
                    if numberOfDays < 2 {
                        return false
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            }
        } else {
            return false
        }
    }
    
    func saveBiometricAuthRequestTimeInUserDefault() {
        let dateData: [String: Any] = ["date": Date()]
        UserDefaults().setValue(dateData, forKey: "authorizationResponse")
    }
    
        func fetchBiometricAuthRequestTimeFromUserDefault() -> Date? {
            if let dateData = UserDefaults().value(forKey: "authorizationResponse") as? [String: Any],
               let date = dateData["date"] as? Date {
                return date
            } else {
                return nil
            }
        }
    
    func handleBiometricAuthorization(handler: @escaping ((Bool) -> Void)) {
        guard biometricLoginEnabled else {
            handler(false)
            return
        }
        let context = LAContext()
        var contextError: NSError?
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &contextError) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authentication required for sign in.") { result, error in
                if  contextError != nil {
                    handler(false)
                    return
                }
                else {
                    if result {
                        self.userManager.password = self.userManager.storedPassword ?? ""
                        handler(true)
                    } else {
                        handler(false)
                    }
                }
            }
        }
    }
    
    func setupBioMetricAuthentication(completionHandler: @escaping(Bool) -> ()) {
        let context = LAContext()
        var contextError: NSError?
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &contextError) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authentication required for sign in.") { result, error in
                if  contextError != nil {
                    completionHandler(false)
                } else {
                    if result {
                        if result {
                            DispatchQueue.main.async {
                                self.biometricLoginEnabled = true
                                self.updateCredentialsOnKeyChain { _ in }
                                UserDefaults().setValue(true, forKey: "biometricAuthAuthorized")
                                completionHandler(true)
                            }
                        }
                    } else {
                        completionHandler(false)
                    }
                }
            }
        }
    }
    
    func updateSigninState(_ status: Bool) {
        DispatchQueue.main.async {
            self.userManager.userLoggedIn = status
        }
    }
}

extension Date {
    
    func daysBetweenDates(startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: self)
        let numberOfDays = components.day ?? 0
        return numberOfDays
    }
}


