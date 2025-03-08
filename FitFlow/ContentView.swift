//
//  ContentView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var healthManager: HealthManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workout Schedule (Today) Tab
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(0)
            
            // Routines Tab
            RoutinesView()
                .tabItem {
                    Label("Routines", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Exercises Tab
            ExercisesView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }
                .tag(2)
            
            // Schedule Tab
            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar.badge.clock")
                }
                .tag(3)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
                .tag(4)
        }
        .tint(Color(hex: "CDCDAB"))
        // Show a workout view overlay when a workout is in progress
        .overlay {
            if healthManager.workoutInProgress {
                workoutInProgressBanner
            }
        }
        // Use standard background color for the app
        .background(AppTheme.primaryBackground)
    }
    
    // Banner that appears when a workout is in progress
    private var workoutInProgressBanner: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                
                Text("Workout in Progress")
                    .font(AppTheme.headlineFont)
                
                Spacer()
                
                Button(action: {
                    selectedTab = 0 // Switch to Today tab where the active workout is
                }) {
                    Text("Continue")
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentColor)
                        .cornerRadius(AppTheme.smallCornerRadius)
                }
            }
            .padding()
            .background(AppTheme.secondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .padding()
            .modifier(AppTheme.subtleShadow.apply())
            
            Spacer()
        }
        .transition(.move(edge: .top))
        .animation(.spring(), value: healthManager.workoutInProgress)
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthManager.shared)
        .environmentObject(DataController.preview)
}
