import SwiftUICore
struct ExercisesView: View {
    @EnvironmentObject var dataController: DataController
    @StateObject private var viewModel = RoutineViewModel()
    @State private var showingAddCustomExercise = false
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise?
    @State private var isRefreshing = false
    @State private var showingRefreshAlert = false
    
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
                    HStack {
                        // Refresh button to fetch more exercises
                        Button {
                            showingRefreshAlert = true
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .disabled(isRefreshing)
                        
                        // Add custom exercise button
                        Button {
                            showingAddCustomExercise = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(AppTheme.textPrimary)
                        }
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
            // Present exercise detail view
            .sheet(isPresented: $showingExerciseDetail) {
                if let exercise = selectedExercise {
                    ExerciseDetailView(exercise: exercise)
                }
            }
            .alert("Refresh Exercise Database", isPresented: $showingRefreshAlert) {
                Button("Refresh All", role: .destructive) {
                    refreshExercises()
                }
                Button("Refresh One Type", role: .none) {
                    refreshOneExerciseType()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to refresh the exercise database from API Ninjas?")
            }
        }
        .overlay {
            // Show loading indicator when refreshing
            if isRefreshing {
                ZStack {
                    Color.black.opacity(0.4)
                    
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color(hex: "CDCDAB"))
                        
                        Text("Updating exercises...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            viewModel.fetchExercises()
        }
    }
    
    // Refresh all exercises from API
    private func refreshExercises() {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        ExerciseAPIService.shared.importAllExercises { count in
            viewModel.fetchExercises()
            isRefreshing = false
        }
    }
    
    // Refresh just one type of exercise
    private func refreshOneExerciseType() {
        guard !isRefreshing else { return }
        
        // Pick a random type to refresh
        let types = ["cardio", "strength", "stretching"]
        let randomType = types.randomElement() ?? "strength"
        
        isRefreshing = true
        ExerciseAPIService.shared.fetchExercises(type: randomType)
        
        // Wait a few seconds then update the UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            viewModel.fetchExercises()
            isRefreshing = false
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
                        
                        if let eq = exercise.equipment, !eq.isEmpty, eq != "None" {
                            Text("•")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(eq)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        if let mg = exercise.muscleGroup, !mg.isEmpty {
                            Text("•")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(mg)
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

// Enhanced ExerciseDetailView
struct ExerciseDetailView: View {
    let exercise: Exercise
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise name
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 4)
                    
                    // Description
                    if let description = exercise.descrip, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                        }
                        .padding()
                        .background(AppTheme.secondaryBackground.opacity(0.5))
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    
                    // Metadata
                    HStack(spacing: 15) {
                        metadataCard(title: "Category", value: exercise.category ?? "Unknown", icon: "figure.strengthtraining.traditional")
                        
                        metadataCard(title: "Muscle Group", value: exercise.muscleGroup ?? "Unknown", icon: "figure.mixed.cardio")
                    }
                    
                    HStack(spacing: 15) {
                        metadataCard(title: "Equipment", value: exercise.equipment ?? "None", icon: "dumbbell")
                        
                        // Placeholder for difficulty (not in current model)
                        metadataCard(title: "Type", value: exercise.isCustom ? "Custom" : "Standard", icon: "star")
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        
                        Text(exercise.instructionsText ?? "No instructions available")
                            .font(.body)
                    }
                    .padding()
                    .background(AppTheme.secondaryBackground.opacity(0.5))
                    .cornerRadius(AppTheme.cornerRadius)
                }
                .padding()
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
    
    private func metadataCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accentColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
}
