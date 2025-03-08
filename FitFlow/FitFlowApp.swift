//
//  FitFlowApp.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

@main
struct FitFlowApp: App {
    // Environment data controller
    @StateObject private var dataController = DataController.shared
    
    // Health manager for HealthKit integration
    @StateObject private var healthManager = HealthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
                .environmentObject(healthManager)
                .onAppear {
                    // Request HealthKit permissions when app launches
                    healthManager.requestAuthorization { success, error in
                        if !success {
                            print("HealthKit authorization denied or restricted")
                            if let error = error {
                                print("HealthKit authorization error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
        }
    }
}
