//
//  AppView_V2.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 12/6/23.
//

import SwiftUI
import SwiftData
import TipKit

import PopupKit
import AlpineCore

public struct AppView_V2<App: View>: View {
    
    @ViewBuilder var app: (_ userID: String) -> App
    @ObservedObject var manager = ConnectManager.shared
    
    var info: LoginConnectionInfo
    
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([CoreUser.self])
        let storeURL = URL.documentsDirectory.appending(path: "Core App Data.sqlite")
        let modelConfiguration = ModelConfiguration("Core App Data", schema: schema, groupContainer: .none)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            CoreAppControl.shared.modelContainer = container
            return container
        }
        catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    public init(info: LoginConnectionInfo, @ViewBuilder app: @escaping (_ userID: String) -> App) {
        self.info = info
        self.app = app

        print(code: .info, try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false))
        print(code: .info, FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.alpinelis.atlas")!.absoluteString)
        
//        try? Tips.resetDatastore()
        try? Tips.configure([.datastoreLocation(.applicationDefault), .displayFrequency(.immediate)])
        
    }
    
    public var body: some View {
        host
            .popupPresenter
            .uiOrientationGetter
            .environmentObject(manager)
            .modelContainer(sharedModelContainer)
    }
    
    @ViewBuilder var host: some View {
        if manager.isSignedIn {
            UserAppView(userID: manager.userID) {
                app(manager.userID)
                    .environmentObject(LocationManager.shared)
            }
            .transition(.opacity)
            .onDisappear {
                if !manager.isSignedIn {
                    ConnectManager.signout()
                }
            }
        }
        else {
            AlpineLoginView_V2(info: info)
                .transition(.move(edge: .bottom))
        }
    }
}
