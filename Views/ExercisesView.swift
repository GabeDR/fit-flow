//
//  ExercisesView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = RoutineViewModel()
    @State private var showingAddCustomExercise = false
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Filter chips
                    filterChips
                    
                    // Display filtered exercises
                    if viewModel.filteredExercises.isEmpty {
                        emptyResultsView
                    } else {
                        exercisesList
                    }
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCustomExercise = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            // Present the form to create a new custom exercise
            .sheet(isPresented: $showingAddCustomExercise) {
                CustomExerciseFormView(viewModel: viewModel) { newExercise in
                    // After saving in the form, re-fetch or do any updates
                    viewModel.fetchExercises()
                }
            }
        }
    }
    
    // MARK: - Search bar
    private var searchBar: some View {
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
    }
    
    // MARK: - Filter chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Muscle group chips
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
                
                // Category chips
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
                
                // Equipment chips
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
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
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
    
    // MARK: - Exercises list
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    exerciseCard(exercise)
                }
            }
            .padding()
        }
    }
    
    private func exerciseCard(_ exercise: Exercise) -> some View {
        Button {
            selectedExercise = exercise
            showingExerciseDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Show name / category
                    Text(exercise.name ?? "Unknown")
                        .font(AppTheme.bodyFont.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 12) {
                        Text(exercise.category ?? "Unknown")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if let eq = exercise.equipment, !eq.isEmpty {
                            Text(eq)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding()
            .background(AppTheme.secondaryBackground.opacity(0.5))
            .cornerRadius(AppTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty results
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
            
            Text("No exercises found")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Try a different search term or clear filters")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.searchText = ""
                viewModel.selectedMuscleGroup = nil
                viewModel.selectedCategory = nil
                viewModel.selectedEquipment = nil
            } label: {
                Text("Clear Filters")
                    .font(AppTheme.bodyFont)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, 50)
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    ExercisesView()
        .environmentObject(DataController.preview)
}

// MARK: - Minimal ExerciseDetailView
struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(spacing: 16) {
            Text(exercise.name ?? "Unknown Exercise")
                .font(.title)
                .padding(.bottom, 4)
            
            Text(exercise.descrip ?? "No description available.")
                .font(.body)
            
            // Additional detail UI here
        }
        .padding()
        .navigationTitle("Exercise Details")
    }
}

// MARK: - Minimal CustomExerciseFormView
struct CustomExerciseFormView: View {
    @ObservedObject var viewModel: RoutineViewModel
    let onSave: (Exercise) -> Void
    
    // Very basic fields
    @State private var name = ""
    @State private var description = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Info")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Create Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let exercise = viewModel.createExercise(
                            name: name,
                            description: description,
                            category: .strength,
                            muscleGroup: .other,
                            equipment: .none,
                            instructions: "N/A"
                        )
                        onSave(exercise)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
