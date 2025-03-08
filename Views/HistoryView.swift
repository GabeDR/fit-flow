//
//  TodayView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI
import HealthKit
import CoreData

struct HistoryView: View {
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var healthManager: HealthManager
    @State private var completedWorkouts: [NSManagedObject] = []
    @State private var healthKitWorkouts: [HKWorkout] = []
    @State private var selectedTimeRange: TimeRange = .week
    
    // Time range selection options
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range selector
                        timeRangeSelector
                        
                        // Stats summary cards
                        statisticsSummary
                        
                        // Workout history
                        workoutHistorySection
                    }
                    .padding()
                }
            }
            .navigationTitle("History")
            .onAppear {
                fetchCompletedWorkouts()
                fetchHealthKitWorkouts()
            }
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    selectedTimeRange = range
                    fetchCompletedWorkouts()
                    fetchHealthKitWorkouts()
                }) {
                    Text(range.rawValue)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(selectedTimeRange == range ? AppTheme.primaryBackground : AppTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTimeRange == range ? AppTheme.accentColor : AppTheme.secondaryBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Statistics Summary
    private var statisticsSummary: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Workouts completed
                statisticCard(
                    title: "Workouts",
                    value: "\(completedWorkouts.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: AppTheme.accentColor
                )
                
                // Total minutes
                statisticCard(
                    title: "Minutes",
                    value: "\(totalMinutes)",
                    icon: "clock",
                    color: AppTheme.strengthColor
                )
            }
            
            HStack(spacing: 16) {
                // Exercises completed
                statisticCard(
                    title: "Exercises",
                    value: "\(totalExercisesCompleted)",
                    icon: "dumbbell",
                    color: AppTheme.cardioColor
                )
                
                // Calories burned
                statisticCard(
                    title: "Calories",
                    value: "\(totalCaloriesBurned)",
                    icon: "flame",
                    color: AppTheme.flexibilityColor
                )
            }
        }
    }
    
    // Reusable card
    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Workout History
    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout History")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            if completedWorkouts.isEmpty {
                emptyHistoryView
            } else {
                ForEach(completedWorkouts, id: \.objectID) { workout in
                    workoutHistoryCard(workout)
                }
            }
        }
    }
    
    private func workoutHistoryCard(_ workout: NSManagedObject) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    let routineName = getRoutineName(from: workout)
                    
                    Text(routineName)
                        .font(AppTheme.bodyFont.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let startDate = workout.value(forKey: "startDate") as? Date {
                        Text(formatDate(startDate))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                Text(formattedDuration(for: workout))
                    .font(AppTheme.captionFont.monospacedDigit())
                    .padding(6)
                    .background(AppTheme.accentColor.opacity(0.3))
                    .cornerRadius(AppTheme.smallCornerRadius)
            }
            
            // Exercise summary
            let setGroups = getCompletedSetGroups(from: workout)
            if !setGroups.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Summary")
                        .font(AppTheme.captionFont.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    // Show up to 3
                    ForEach(Array(setGroups.prefix(3)), id: \.objectID) { setGroup in
                        HStack {
                            Text(getExerciseName(from: setGroup))
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Text("\(getCompletedSetsCount(from: setGroup)) sets")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    // If more than 3, show how many remain
                    if setGroups.count > 3 {
                        Text("+ \(setGroups.count - 3) more...")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.3))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
            
            Text("No workout history")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Complete a workout to see your history")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.secondaryBackground.opacity(0.2))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Helper Methods
    private func getRoutineName(from workout: NSManagedObject) -> String {
        if let routine = workout.value(forKey: "routine") as? NSManagedObject,
           let name = routine.value(forKey: "name") as? String {
            return name
        }
        return "Unknown Workout"
    }
    
    private func formattedDuration(for workout: NSManagedObject) -> String {
        if let startDate = workout.value(forKey: "startDate") as? Date,
           let endDate = workout.value(forKey: "endDate") as? Date {
            let duration = endDate.timeIntervalSince(startDate)
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
            return formatter.string(from: duration) ?? "0s"
        }
        return "0s"
    }
    
    // **Returns a non-optional array** of set-groups; just empty if none
    private func getCompletedSetGroups(from workout: NSManagedObject) -> [NSManagedObject] {
        if let setGroupsSet = workout.value(forKey: "completedSetGroups") as? NSSet {
            return setGroupsSet.allObjects as? [NSManagedObject] ?? []
        }
        return []
    }
    
    private func getExerciseName(from setGroup: NSManagedObject) -> String {
        if let template = setGroup.value(forKey: "template") as? NSManagedObject,
           let exercise = template.value(forKey: "exercise") as? NSManagedObject,
           let name = exercise.value(forKey: "name") as? String {
            return name
        }
        return "Unknown Exercise"
    }
    
    private func getCompletedSetsCount(from setGroup: NSManagedObject) -> Int {
        if let setsSet = setGroup.value(forKey: "completedSets") as? NSSet {
            return setsSet.count
        }
        return 0
    }
    
    // MARK: - Fetch from Core Data
    private func fetchCompletedWorkouts() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CompletedWorkout")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        // Filter by time range
        if selectedTimeRange != .all {
            let endDate = Date()
            let startDate: Date
            
            switch selectedTimeRange {
            case .week:
                startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
            case .month:
                startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
            case .year:
                startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
            case .all:
                startDate = Date.distantPast
            }
            
            request.predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", startDate as NSDate, endDate as NSDate)
        }
        
        do {
            completedWorkouts = try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching completed workouts: \(error.localizedDescription)")
            completedWorkouts = []
        }
    }
    
    // MARK: - Fetch from HealthKit
    private func fetchHealthKitWorkouts() {
        // Skip if HealthKit is not authorized
        guard healthManager.isAuthorized else { return }
        
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        case .year:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        case .all:
            startDate = Date.distantPast
        }
        
        healthManager.getWorkouts(limit: 100) { workouts, error in
            if let workouts = workouts {
                // Filter workouts by date range
                self.healthKitWorkouts = workouts.filter { workout in
                    workout.startDate >= startDate && workout.endDate <= endDate
                }
            } else if let error = error {
                print("Error fetching HealthKit workouts: \(error.localizedDescription)")
                self.healthKitWorkouts = []
            }
        }
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Computed Stats
    private var totalMinutes: Int {
        let total = completedWorkouts.reduce(0) { sum, workout in
            guard
                let start = workout.value(forKey: "startDate") as? Date,
                let end = workout.value(forKey: "endDate") as? Date
            else {
                return sum
            }
            return sum + Int(end.timeIntervalSince(start) / 60)
        }
        return total
    }
    
    private var totalExercisesCompleted: Int {
        completedWorkouts.reduce(0) { sum, workout in
            let setGroups = getCompletedSetGroups(from: workout)
            return sum + setGroups.count
        }
    }
    
    // Sum of HealthKit calories over the selected time range
    private var totalCaloriesBurned: Int {
        healthKitWorkouts.reduce(0) { sum, workout in
            if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                return sum + Int(calories)
            }
            return sum
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(DataController.preview)
        .environmentObject(HealthManager.shared)
}
