//
//  reMind_appleDartsApp.swift
//  reMind_appleDarts
//
//  Created by Sumi on 30/5/2025.
//

import SwiftUI

@main
struct reMind_appleDartsApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
