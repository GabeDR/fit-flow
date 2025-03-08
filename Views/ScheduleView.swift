//
//  TodayView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = RoutineViewModel()
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 1
    @State private var showingRoutinePicker = false
    
    // Days of week
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let fullDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Weekly calendar view
                    weekCalendar
                    
                    // Day detail view
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header for selected day
                            dayHeader
                            
                            // Scheduled workouts for the selected day
                            scheduledWorkoutsSection
                            
                            // Weekly overview section
                            weeklyOverviewSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Schedule")
            .onAppear {
                viewModel.fetchRoutines()
            }
            .sheet(isPresented: $showingRoutinePicker) {
                RoutinePickerView(viewModel: viewModel, selectedDay: selectedDay) { routine in
                    viewModel.scheduleRoutine(routine, for: selectedDay)
                }
            }
        }
    }
    
    // Weekly calendar view for selecting days
    private var weekCalendar: some View {
        HStack(spacing: 0) {
            ForEach(0..<7) { day in
                Button(action: {
                    selectedDay = day
                }) {
                    VStack(spacing: 8) {
                        Text(days[day])
                            .font(AppTheme.captionFont)
                            .foregroundColor(selectedDay == day ? AppTheme.primaryBackground : AppTheme.textSecondary)
                        
                        // Day number (or dot for today)
                        ZStack {
                            if isToday(day) {
                                Circle()
                                    .fill(selectedDay == day ? AppTheme.accentColor : AppTheme.secondaryBackground)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Indicator for scheduled workouts
                        if hasScheduledWorkouts(for: day) {
                            Circle()
                                .fill(selectedDay == day ? AppTheme.primaryBackground : AppTheme.accentColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedDay == day ? AppTheme.accentColor : AppTheme.primaryBackground)
                }
            }
        }
        .background(AppTheme.primaryBackground)
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
    }
    
    // Header for the selected day
    private var dayHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(fullDays[selectedDay])
                    .font(AppTheme.titleFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                if isToday(selectedDay) {
                    Text("Today")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accentColor.opacity(0.2))
                        .cornerRadius(AppTheme.smallCornerRadius)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingRoutinePicker = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.secondaryBackground)
                    .cornerRadius(20)
            }
        }
    }
    
    // Section for scheduled workouts on the selected day
    private var scheduledWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scheduled Workouts")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            let routines = getRoutinesForDay(selectedDay)
            
            if routines.isEmpty {
                emptyScheduleView
            } else {
                ForEach(routines) { routine in
                    scheduledRoutineCard(routine)
                }
            }
        }
    }
    
    // Card for a scheduled routine
    private func scheduledRoutineCard(_ routine: WorkoutRoutine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Replace <#default value#> with "Unknown Routine"
                Text(routine.name ?? "Unknown Routine")
                    .font(AppTheme.bodyFont.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(routineSummary(routine))
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.unscheduleRoutine(routine, from: selectedDay)
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Empty state for when no workouts are scheduled
    private var emptyScheduleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
            
            Text("No workouts scheduled")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Button(action: {
                showingRoutinePicker = true
            }) {
                Text("Add Workout")
                    .font(AppTheme.bodyFont)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.secondaryBackground.opacity(0.2))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Weekly overview section
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Overview")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(0..<7) { day in
                    weekDayRow(day)
                }
            }
            .padding()
            .background(AppTheme.secondaryBackground.opacity(0.2))
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
    
    // Row for a day in the weekly overview
    private func weekDayRow(_ day: Int) -> some View {
        HStack {
            Text(fullDays[day])
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 100, alignment: .leading)
            
            if isToday(day) {
                Text("Today")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentColor.opacity(0.2))
                    .cornerRadius(AppTheme.smallCornerRadius)
            }
            
            Spacer()
            
            let routines = getRoutinesForDay(day)
            
            if routines.isEmpty {
                Text("Rest Day")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                // Replace <#default value#> with "Unknown Routine"
                Text(routines.map { $0.name ?? "Unknown Routine" }.joined(separator: ", "))
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
    
    // Check if the given day is today
    private func isToday(_ day: Int) -> Bool {
        let currentWeekday = Calendar.current.component(.weekday, from: Date()) - 1
        return day == currentWeekday
    }
    
    // Check if the given day has scheduled workouts
    private func hasScheduledWorkouts(for day: Int) -> Bool {
        !getRoutinesForDay(day).isEmpty
    }
    
    // Get routines scheduled for a specific day
    private func getRoutinesForDay(_ day: Int) -> [WorkoutRoutine] {
        return viewModel.getRoutinesForDay(day)
    }
    
    // Get a summary of a routine (exercise count)
    private func routineSummary(_ routine: WorkoutRoutine) -> String {
        let warmupCount = routine.warmupExercisesArray.count
        let mainCount = routine.mainExercisesArray.count
        let cooldownCount = routine.cooldownExercisesArray.count
        let totalCount = warmupCount + mainCount + cooldownCount
        
        return "\(totalCount) exercises • \(estimatedDuration(routine)) mins"
    }
    
    // Estimate workout duration based on exercise count and typical times
    private func estimatedDuration(_ routine: WorkoutRoutine) -> Int {
        // Rough estimation: 5 mins per exercise
        let exerciseCount = routine.warmupExercisesArray.count + routine.mainExercisesArray.count + routine.cooldownExercisesArray.count
        return max(10, exerciseCount * 5)
    }
}

// Routine picker for scheduling
struct RoutinePickerView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let selectedDay: Int
    let onSelect: (WorkoutRoutine) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    // Compute filtered routines
    private var filteredRoutines: [WorkoutRoutine] {
        if searchText.isEmpty {
            return viewModel.routines
        } else {
            // Replace <#default value#> with "false" for boolean fallback
            return viewModel.routines.filter { routine in
                (routine.name?.lowercased().contains(searchText.lowercased()) ?? false)
                || (routine.notes?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textSecondary)
                    
                    TextField("Search routines", text: $searchText)
                        .font(AppTheme.bodyFont)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding()
                .background(AppTheme.secondaryBackground.opacity(0.5))
                
                // Routine list
                if filteredRoutines.isEmpty {
                    emptyResultsView
                } else {
                    List {
                        ForEach(filteredRoutines) { routine in
                            Button(action: {
                                onSelect(routine)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                routineRow(routine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchRoutines()
            }
        }
    }
    
    // Row for a routine in the list
    private func routineRow(_ routine: WorkoutRoutine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Replace <#default value#> with "Unknown Routine"
                Text(routine.name ?? "Unknown Routine")
                    .font(AppTheme.bodyFont.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                let exerciseCount = routine.warmupExercisesArray.count
                    + routine.mainExercisesArray.count
                    + routine.cooldownExercisesArray.count
                
                Text("\(exerciseCount) exercises")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .foregroundColor(AppTheme.accentColor)
        }
        .padding(.vertical, 8)
    }
    
    // Empty results view
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
            
            Text("No routines found")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Try a different search term or create a new routine")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(DataController.preview)
}
