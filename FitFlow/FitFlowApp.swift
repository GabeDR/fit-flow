//
//  FitFlowApp.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI
import CoreData

@main
struct FitFlowApp: App {
    // Environment data controller
    @StateObject private var dataController = DataController.shared
    
    // Health manager for HealthKit integration
    @StateObject private var healthManager = HealthManager.shared
    
    // State for tracking API data loading
    @State private var isLoadingExercises = false
    @State private var showLoadingIndicator = false
    
    init() {
        // Check if we need to load exercises
        checkAndLoadExercises()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
                
                // Loading overlay if fetching exercises
                if showLoadingIndicator {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color(hex: "CDCDAB"))
                            
                            Text("Loading Exercises...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func checkAndLoadExercises() {
        // Check if we need to load exercises (first launch or no exercises)
        let context = dataController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Exercise")
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                // No exercises found, fetch from API
                loadExercisesFromAPI()
            }
        } catch {
            print("Error checking exercise count: \(error)")
        }
    }
    
    private func loadExercisesFromAPI() {
        guard !isLoadingExercises else { return }
        
        isLoadingExercises = true
        showLoadingIndicator = true
        
        ExerciseAPIService.shared.importAllExercises { count in
            isLoadingExercises = false
            showLoadingIndicator = false
            
            print("Loaded \(count) exercises from API")
            
            // If API failed (count == 0), load from local JSON as fallback
            if count == 0 {
                DispatchQueue.main.async {
                    self.dataController.loadExercisesFromJSON()
                }
            }
        }
    }
}
