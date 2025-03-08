//
//  TodayView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//
import SwiftUI
import CoreData

struct TodayView: View {
    @EnvironmentObject var dataController: DataController
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var routineViewModel = RoutineViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    
    @State private var selectedRoutine: NSManagedObject?
    @State private var showingWorkoutView = false
    @State private var showingQuickStartOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with today's date
                        todayHeader
                        
                        // Active workout card (if a workout is in progress)
                        if healthManager.workoutInProgress {
                            activeWorkoutCard
                                .transition(.scale)
                        } else {
                            // Scheduled workouts for today
                            todayWorkoutsSection
                            
                            // Quick start button
                            quickStartButton
                        }
                        
                        // Recent workouts section
                        recentWorkoutsSection
                    }
                    .padding()
                }
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Refresh data
                            routineViewModel.fetchRoutines()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                .sheet(isPresented: $showingWorkoutView) {
                    if let routine = selectedRoutine {
                        WorkoutActiveView(routine: routine as! WorkoutRoutine, workoutViewModel: workoutViewModel)
                    }
                }
                .actionSheet(isPresented: $showingQuickStartOptions) {
                    ActionSheet(
                        title: Text("Quick Start Workout"),
                        message: Text("Choose a routine to start"),
                        buttons: quickStartButtons
                    )
                }
            }
        }
        .onAppear {
            routineViewModel.fetchRoutines()
        }
    }
    
    // Today's date header
    private var todayHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedDate())
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(weekdayName())
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
    
    // Active workout card that shows when a workout is in progress
    private var activeWorkoutCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                
                Text("Active Workout")
                    .font(AppTheme.headlineFont)
                
                Spacer()
                
                Text(formatDuration(healthManager.workoutDuration))
                    .font(AppTheme.bodyFont.monospacedDigit())
                    .padding(6)
                    .background(AppTheme.accentColor.opacity(0.3))
                    .cornerRadius(AppTheme.smallCornerRadius)
            }
            
            Divider()
            
            // Current heart rate and calories
            HStack(spacing: 20) {
                MetricView(
                    icon: "heart.fill",
                    iconColor: .red,
                    value: "\(Int(healthManager.currentHeartRate))",
                    unit: "bpm"
                )
                
                Divider()
                
                MetricView(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(Int(healthManager.activeCaloriesBurned))",
                    unit: "cal"
                )
            }
            
            Button(action: {
                showingWorkoutView = true
            }) {
                Text("Continue Workout")
                    .font(AppTheme.bodyFont.weight(.medium))
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .cardStyle()
    }
    
    // Section showing workouts scheduled for today
    private var todayWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workouts")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            let todaysRoutines = getTodaysRoutines()
            
            if todaysRoutines.isEmpty {
                // Show placeholder when no workouts are scheduled
                Text("No workouts scheduled for today")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.secondaryBackground.opacity(0.5))
                    .cornerRadius(AppTheme.cornerRadius)
            } else {
                // List scheduled workouts
                ForEach(todaysRoutines, id: \.objectID) { routine in
                    routineCard(routine)
                }
            }
        }
    }
    
    // Quick start button for unplanned workouts
    private var quickStartButton: some View {
        Button(action: {
            showingQuickStartOptions = true
        }) {
            HStack {
                Image(systemName: "play.fill")
                Text("Quick Start")
                    .font(AppTheme.bodyFont.weight(.medium))
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.vertical, 8)
    }
    
    // Recent workouts history section
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            let recentWorkouts = getRecentCompletedWorkouts()
            
            if recentWorkouts.isEmpty {
                Text("No recent workouts")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.secondaryBackground.opacity(0.5))
                    .cornerRadius(AppTheme.cornerRadius)
            } else {
                ForEach(recentWorkouts, id: \.objectID) { completedWorkout in
                    completedWorkoutCard(completedWorkout)
                }
            }
        }
    }
    
    // Card displaying a routine
    private func routineCard(_ routine: NSManagedObject) -> some View {
        Button(action: {
            selectedRoutine = routine
            showingWorkoutView = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.value(forKey: "name") as? String ?? "Unnamed Routine")
                        .font(AppTheme.bodyFont.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(workoutSummary(routine))
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding()
            .background(AppTheme.secondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Card displaying a completed workout
    private func completedWorkoutCard(_ workout: NSManagedObject) -> some View {
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
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Helper to get routine name
    private func getRoutineName(from workout: NSManagedObject) -> String {
        if let routine = workout.value(forKey: "routine") as? NSManagedObject,
           let name = routine.value(forKey: "name") as? String {
            return name
        }
        return "Unknown Workout"
    }
    
    // Format duration for a completed workout
    private func formattedDuration(for workout: NSManagedObject) -> String {
        guard let startDate = workout.value(forKey: "startDate") as? Date,
              let endDate = workout.value(forKey: "endDate") as? Date else {
            return "0s"
        }
        
        let duration = endDate.timeIntervalSince(startDate)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    // Get workouts scheduled for today
    private func getTodaysRoutines() -> [NSManagedObject] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date()) - 1 // 0-based for our data model
        return routineViewModel.getRoutinesForDay(weekday)
    }
    
    // Get recently completed workouts
    private func getRecentCompletedWorkouts() -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CompletedWorkout")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 3
        
        do {
            return try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching completed workouts: \(error.localizedDescription)")
            return []
        }
    }
    
    // Format today's date
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    // Get weekday name (Monday, Tuesday, etc)
    private func weekdayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    // Format workout duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get summary of a workout (exercise count, duration estimate)
    private func workoutSummary(_ routine: NSManagedObject) -> String {
        // Simplified version using key-value access
        let totalExercises = getExerciseCount(routine, relationship: "warmupExercises") +
                             getExerciseCount(routine, relationship: "mainExercises") +
                             getExerciseCount(routine, relationship: "cooldownExercises")
        
        return "\(totalExercises) exercises • \(estimatedDuration(totalExercises)) mins"
    }
    
    // Helper to get the count of exercises in a relationship
    private func getExerciseCount(_ routine: NSManagedObject, relationship: String) -> Int {
        if let exercisesSet = routine.value(forKey: relationship) as? NSSet {
            return exercisesSet.count
        }
        return 0
    }
    
    // Estimate workout duration based on exercise count
    private func estimatedDuration(_ exerciseCount: Int) -> Int {
        // Rough estimation: 5 mins per exercise
        return max(10, exerciseCount * 5)
    }
    
    // Buttons for quick start action sheet
    private var quickStartButtons: [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = routineViewModel.routines.map { routine in
            .default(Text(routine.value(forKey: "name") as? String ?? "Unnamed Routine")) {
                selectedRoutine = routine
                showingWorkoutView = true
            }
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
}

// Reusable workout metric view
struct MetricView: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.system(.title3, design: .rounded).monospacedDigit().bold())
                
                Text(unit)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TodayView()
        .environmentObject(DataController.preview)
        .environmentObject(HealthManager.shared)
}
