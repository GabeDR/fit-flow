//
//  RoutinesView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

struct RoutinesView: View {
    @StateObject private var viewModel = RoutineViewModel()
    @State private var showingAddRoutine = false
    @State private var showingEditRoutine = false
    @State private var selectedRoutine: WorkoutRoutine?
    @State private var routineName = ""
    @State private var routineNotes = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Workout Routines")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddRoutine = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
                // Present sheet for adding a routine
                .sheet(isPresented: $showingAddRoutine) {
                    routineFormView(title: "New Routine", buttonText: "Create") {
                        let trimmed = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            viewModel.createRoutine(name: trimmed, notes: routineNotes)
                            routineName = ""
                            routineNotes = ""
                        }
                    }
                }
                // Present sheet for editing a routine
                .sheet(isPresented: $showingEditRoutine) {
                    routineFormView(title: "Edit Routine", buttonText: "Save") {
                        let trimmed = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let routine = selectedRoutine, !trimmed.isEmpty {
                            viewModel.updateRoutine(routine, name: trimmed, notes: routineNotes)
                            routineName = ""
                            routineNotes = ""
                        }
                    }
                }
                // Delete confirmation
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete Routine"),
                        message: Text("Are you sure you want to delete this routine? This cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            if let routine = selectedRoutine {
                                viewModel.deleteRoutine(routine)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .onAppear {
                    viewModel.fetchRoutines()
                }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            AppTheme.primaryBackground.ignoresSafeArea()
            
            if viewModel.routines.isEmpty {
                emptyStateView
            } else {
                routineListView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.accentColor)
            
            Text("No Workout Routines")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Create your first workout routine to get started")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddRoutine = true
            } label: {
                Text("Create Routine")
                    .font(AppTheme.bodyFont)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .padding()
    }
    
    // MARK: - Routine List
    private var routineListView: some View {
        List {
            ForEach(viewModel.routines) { routine in
                NavigationLink(
                    destination: RoutineDetailView(routine: routine, viewModel: viewModel)
                ) {
                    routineRow(routine)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        selectedRoutine = routine
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        selectedRoutine = routine
                        routineName = routine.name ?? ""
                        routineNotes = routine.notes ?? ""
                        showingEditRoutine = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Routine Row
    private func routineRow(_ routine: WorkoutRoutine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name ?? "Unknown Routine")
                .font(AppTheme.bodyFont.weight(.medium))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(routineSummary(routine))
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Routine Form
    private func routineFormView(
        title: String,
        buttonText: String,
        onSave: @escaping () -> Void
    ) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Details").font(AppTheme.captionFont)) {
                    TextField("Routine Name", text: $routineName)
                        .font(AppTheme.bodyFont)
                    
                    ZStack(alignment: .topLeading) {
                        if routineNotes.isEmpty {
                            Text("Notes (optional)")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $routineNotes)
                            .font(AppTheme.bodyFont)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddRoutine = false
                        showingEditRoutine = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(buttonText) {
                        onSave()
                        showingAddRoutine = false
                        showingEditRoutine = false
                    }
                    .disabled(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Summary Helpers
    private func routineSummary(_ routine: WorkoutRoutine) -> String {
        let warmupCount = routine.warmupExercisesArray.count
        let mainCount = routine.mainExercisesArray.count
        let cooldownCount = routine.cooldownExercisesArray.count
        let totalCount = warmupCount + mainCount + cooldownCount
        
        let lastPerformedText: String
        if let lastPerformed = routine.lastPerformedDate {
            lastPerformedText = "Last performed: \(formatDate(lastPerformed))"
        } else {
            lastPerformedText = "Not performed yet"
        }
        
        return "\(totalCount) exercises • \(lastPerformedText)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Improved RoutineDetailView
struct RoutineDetailView: View {
    let routine: WorkoutRoutine
    @ObservedObject var viewModel: RoutineViewModel
    @State private var showingEditRoutine = false
    @State private var routineName = ""
    @State private var routineNotes = ""
    @State private var showingAddExercise = false
    @State private var selectedPhase: WorkoutPhase = .warmup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Routine info card
                routineInfoCard
                
                // Exercise sections by phase
                exerciseSection(title: "Warm-up", phase: .warmup, exercises: routine.warmupExercisesArray)
                exerciseSection(title: "Main Workout", phase: .main, exercises: routine.mainExercisesArray)
                exerciseSection(title: "Cool-down", phase: .cooldown, exercises: routine.cooldownExercisesArray)
            }
            .padding()
        }
        .navigationTitle(routine.name ?? "Routine Detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    routineName = routine.name ?? ""
                    routineNotes = routine.notes ?? ""
                    showingEditRoutine = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditRoutine) {
            editRoutineSheet
        }
        .sheet(isPresented: $showingAddExercise) {
            addExerciseSheet
        }
    }
    
    // Routine info card
    private var routineInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(routine.name ?? "Unknown Routine")
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.textPrimary)
            
            if let notes = routine.notes, !notes.isEmpty {
                Text(notes)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            HStack {
                let totalExercises = routine.warmupExercisesArray.count +
                                    routine.mainExercisesArray.count +
                                    routine.cooldownExercisesArray.count
                
                Label("\(totalExercises) exercises", systemImage: "dumbbell")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                if let createdDate = routine.createdDate {
                    Text("Created: \(formatDate(createdDate))")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Exercise section for a specific phase
    private func exerciseSection(title: String, phase: WorkoutPhase, exercises: [Exercise]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button {
                    selectedPhase = phase
                    showingAddExercise = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(AppTheme.captionFont)
                }
            }
            
            if exercises.isEmpty {
                Text("No exercises added")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.secondaryBackground.opacity(0.3))
                    .cornerRadius(AppTheme.cornerRadius)
            } else {
                ForEach(exercises) { exercise in
                    exerciseRow(exercise, phase: phase)
                }
            }
        }
    }
    
    // Single exercise row
    private func exerciseRow(_ exercise: Exercise, phase: WorkoutPhase) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name ?? "Unknown Exercise")
                    .font(AppTheme.bodyFont.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack {
                    Text(exercise.category ?? "")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    if let muscleGroup = exercise.muscleGroup, !muscleGroup.isEmpty {
                        Text("•")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(muscleGroup)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Get the set info if available
            if let setGroup = exercise.setGroupsArray.first {
                Text("\(setGroup.targetSets) sets")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentColor.opacity(0.2))
                    .cornerRadius(AppTheme.smallCornerRadius)
            }
            
            Button {
                viewModel.removeExerciseFromRoutine(exercise, from: routine, phase: phase)
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.3))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // Edit routine sheet
    private var editRoutineSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Routine Details")) {
                    TextField("Routine Name", text: $routineName)
                    
                    ZStack(alignment: .topLeading) {
                        if routineNotes.isEmpty {
                            Text("Notes (optional)")
                                .foregroundColor(AppTheme.textSecondary)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $routineNotes)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditRoutine = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            viewModel.updateRoutine(routine, name: trimmedName, notes: routineNotes)
                        }
                        showingEditRoutine = false
                    }
                    .disabled(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // Add exercise sheet
    private var addExerciseSheet: some View {
        NavigationView {
            VStack {
                // Search and filter UI
                SearchFilterExerciseView(viewModel: viewModel)
                
                // Exercise list
                List {
                    ForEach(viewModel.filteredExercises) { exercise in
                        Button {
                            viewModel.addExerciseToRoutine(
                                exercise,
                                to: routine,
                                phase: selectedPhase
                            )
                            showingAddExercise = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name ?? "Unknown")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text("\(exercise.category ?? "Unknown") • \(exercise.muscleGroup ?? "Unknown")")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddExercise = false
                    }
                }
            }
            .onAppear {
                viewModel.fetchExercises()
            }
        }
    }
    
    // Helper to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Search and filter component for exercises
struct SearchFilterExerciseView: View {
    @ObservedObject var viewModel: RoutineViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Search exercises", text: $viewModel.searchText)
                    .font(AppTheme.bodyFont)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(AppTheme.secondaryBackground.opacity(0.5))
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Muscle group filter
                    ForEach(MuscleGroup.allCases) { mg in
                        filterChip(
                            title: mg.rawValue,
                            isSelected: viewModel.selectedMuscleGroup == mg
                        ) {
                            if viewModel.selectedMuscleGroup == mg {
                                viewModel.selectedMuscleGroup = nil
                            } else {
                                viewModel.selectedMuscleGroup = mg
                            }
                        }
                    }
                    
                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, 4)
                    
                    // Category filter
                    ForEach(ExerciseCategory.allCases) { cat in
                        filterChip(
                            title: cat.rawValue,
                            isSelected: viewModel.selectedCategory == cat
                        ) {
                            if viewModel.selectedCategory == cat {
                                viewModel.selectedCategory = nil
                            } else {
                                viewModel.selectedCategory = cat
                            }
                        }
                    }
                    
                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, 4)
                    
                    // Equipment filter
                    ForEach(EquipmentType.allCases) { eq in
                        filterChip(
                            title: eq.rawValue,
                            isSelected: viewModel.selectedEquipment == eq
                        ) {
                            if viewModel.selectedEquipment == eq {
                                viewModel.selectedEquipment = nil
                            } else {
                                viewModel.selectedEquipment = eq
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(AppTheme.primaryBackground)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundColor(isSelected ? AppTheme.primaryBackground : AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accentColor : AppTheme.secondaryBackground)
                .cornerRadius(AppTheme.smallCornerRadius)
        }
    }
}

#Preview {
    RoutinesView()
        .environmentObject(DataController.preview)
}
