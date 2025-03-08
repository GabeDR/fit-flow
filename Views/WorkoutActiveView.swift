//
//  TodayView.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//
import SwiftUI
import HealthKit

struct WorkoutActiveView: View {
    // Routine for this workout
    let routine: WorkoutRoutine
    
    // View model
    @ObservedObject var workoutViewModel: WorkoutViewModel
    
    // Environment objects
    @EnvironmentObject var healthManager: HealthManager
    
    // State for alert and confirmation
    @State private var showingExitAlert = false
    @State private var showingCompletionAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppTheme.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Workout header
                workoutHeader
                
                // Progress bar
                workoutProgressBar
                
                // Current exercise view
                if let currentExercise = workoutViewModel.getCurrentExercise() {
                    if workoutViewModel.isResting {
                        // Show rest timer
                        restTimerView
                    } else {
                        // Show exercise instruction
                        exerciseView(currentExercise)
                    }
                } else {
                    // Fallback if no exercise is available
                    Text("No exercise available")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.secondaryBackground)
                }
                
                // Controls at the bottom
                workoutControls
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingExitAlert = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .alert(isPresented: $showingExitAlert) {
            Alert(
                title: Text("Exit Workout"),
                message: Text("Are you sure you want to end this workout? Your progress will be lost."),
                primaryButton: .destructive(Text("End Workout")) {
                    workoutViewModel.cancelWorkout()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingCompletionAlert) {
            Alert(
                title: Text("Workout Complete"),
                message: Text("Great job! You've completed your workout."),
                dismissButton: .default(Text("Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            // Start the workout when the view appears
            workoutViewModel.startWorkout(with: routine)
        }
        .onDisappear {
            // Ensure the workout is properly cancelled if the view is dismissed
            if workoutViewModel.workoutInProgress && !workoutViewModel.workoutCompleted {
                workoutViewModel.cancelWorkout()
            }
        }
    }
    
    // MARK: - Workout Header
    private var workoutHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // FIXED: Use "routine.string" instead of "wrappedName"
                Text(routine.name ?? "Unknown Routine")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(currentPhaseText)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Text(workoutViewModel.formatTime(workoutViewModel.elapsedTime))
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundColor(AppTheme.textPrimary)
                .padding(8)
                .background(AppTheme.secondaryBackground)
                .cornerRadius(AppTheme.smallCornerRadius)
        }
        .padding()
        .background(phaseColor.opacity(0.3))
    }
    
    // MARK: - Progress Bar
    private var workoutProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(AppTheme.progressBackground)
                    .frame(height: 8)
                
                // Progress
                Rectangle()
                    .fill(phaseColor)
                    .frame(width: geometry.size.width * workoutProgress, height: 8)
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Rest Timer
    private var restTimerView: some View {
        VStack(spacing: 20) {
            Text("Rest")
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.textPrimary)
            
            ZStack {
                // Timer circle background
                Circle()
                    .stroke(AppTheme.progressBackground, lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                // Timer progress
                Circle()
                    .trim(from: 0, to: CGFloat(workoutViewModel.currentRestTimer) / 60.0)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Timer text
                Text("\(workoutViewModel.currentRestTimer)")
                    .font(.system(size: 60, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            // FIXED: Use "exercise.name" if it exists
            Text("Next: \(workoutViewModel.getCurrentExercise()?.name ?? "No Name")")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 20)
            
            Button(action: {
                workoutViewModel.skipRest()
            }) {
                Text("Skip Rest")
                    .font(AppTheme.bodyFont)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.top, 20)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.primaryBackground)
        .transition(.opacity)
    }
    
    // MARK: - Exercise View
    private func exerciseView(_ exercise: Exercise) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title & Info
                VStack(spacing: 8) {
                    // FIXED: Use "exercise.name"
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(AppTheme.titleFont)
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    exerciseMetadata(exercise)
                }
                .padding(.bottom, 10)
                
                // Placeholder illustration
                exerciseIllustration(exercise)
                
                // Instructions
                instructionsView(exercise)
                
                // Set counter
                setCounter(exercise)
                
                // Complete button
                Button(action: {
                    workoutViewModel.completeCurrentSet()
                }) {
                    Text("Complete Set")
                        .font(AppTheme.headlineFont)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Skip exercise button
                Button(action: {
                    workoutViewModel.skipCurrentExercise()
                }) {
                    Text("Skip Exercise")
                        .font(AppTheme.bodyFont)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .padding()
        }
        .transition(.opacity)
    }
    
    // MARK: - Exercise Metadata
    private func exerciseMetadata(_ exercise: Exercise) -> some View {
        HStack(spacing: 15) {
            // FIXED: Just show muscleGroup directly (no muscleGroupEnum)
            Label(exercise.muscleGroup ?? "Unknown", systemImage: "figure.mixed.cardio")
                .font(AppTheme.captionFont)
                .padding(6)
                .background(AppTheme.accentColor.opacity(0.3))
                .cornerRadius(AppTheme.smallCornerRadius)
            
            // Equipment label (if needed)
            if let equip = exercise.equipment, !equip.isEmpty {
                Label(equip, systemImage: "dumbbell")
                    .font(AppTheme.captionFont)
                    .padding(6)
                    .background(AppTheme.accentColor.opacity(0.3))
                    .cornerRadius(AppTheme.smallCornerRadius)
            }
        }
    }
    
    // MARK: - Exercise Illustration Placeholder
    private func exerciseIllustration(_ exercise: Exercise) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.secondaryBackground)
                .frame(height: 200)
            
            VStack {
                Image(systemName: exerciseIcon(for: exercise))
                    .font(.system(size: 60))
                    .foregroundColor(phaseColor)
                
                Text("Exercise Demonstration")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    // MARK: - Instructions
    private func instructionsView(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.textPrimary)
            
            // FIXED: Use "exercise.instructionsText" directly
            Text(exercise.instructionsText ?? "No Instructions")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Set Counter
    private func setCounter(_ exercise: Exercise) -> some View {
        VStack(spacing: 12) {
            if let setGroup = workoutViewModel.getCurrentSetGroup(),
               let currentSet = workoutViewModel.getCurrentSet() {
                
                HStack {
                    Text("Set \(workoutViewModel.currentSetIndex + 1) of \(setGroup.targetSets)")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    if currentSet.targetDuration > 0 {
                        Text("\(currentSet.targetDuration) sec")
                            .font(AppTheme.bodyFont.monospacedDigit())
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        HStack(spacing: 4) {
                            Text("\(currentSet.targetReps) reps")
                                .font(AppTheme.bodyFont.monospacedDigit())
                                .foregroundColor(AppTheme.textSecondary)
                            
                            if currentSet.targetWeight > 0 {
                                Text("• \(String(format: "%.1f", currentSet.targetWeight)) kg")
                                    .font(AppTheme.bodyFont.monospacedDigit())
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<Int(setGroup.targetSets), id: \.self) { index in
                        let isCompleted = workoutViewModel.exerciseCompletionState["\(workoutViewModel.currentPhase.rawValue)_\(workoutViewModel.currentExerciseIndex)"]?[index] ?? false
                        let isCurrent = index == workoutViewModel.currentSetIndex
                        
                        Circle()
                            .fill(isCompleted ? phaseColor : (isCurrent ? AppTheme.accentColor : AppTheme.progressBackground))
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground.opacity(0.3))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    // MARK: - Bottom Controls
    private var workoutControls: some View {
        HStack(spacing: 16) {
            // (Optional) Previous phase button
            Button(action: {
                // not implemented
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: AppTheme.iconSize))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .buttonStyle(IconButtonStyle())
            .disabled(true)
            
            // Skip phase
            Button(action: {
                workoutViewModel.skipCurrentPhase()
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "forward.fill")
                    Text("Skip Phase")
                        .font(AppTheme.captionFont)
                }
                .foregroundColor(AppTheme.textPrimary)
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Complete workout
            Button(action: {
                workoutViewModel.completeWorkout()
                showingCompletionAlert = true
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark")
                    Text("Complete")
                        .font(AppTheme.captionFont)
                }
                .foregroundColor(AppTheme.textPrimary)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(AppTheme.primaryBackground)
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
    }
    
    // MARK: - Icon for Exercise
    private func exerciseIcon(for exercise: Exercise) -> String {
        // FIXED: Just reference "exercise.category"
        switch exercise.category ?? "" {
        case "Strength":
            return "figure.strengthtraining.traditional"
        case "Cardio":
            return "figure.run"
        case "Flexibility":
            return "figure.flexibility"
        case "Balance":
            return "figure.mind.and.body"
        case "Plyometric":
            return "figure.boxing"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    // MARK: - Current Phase Text
    private var currentPhaseText: String {
        let warmupCount = (routine.warmupExercises as? Set<Exercise>)?.count ?? 0
        let mainCount = (routine.mainExercises as? Set<Exercise>)?.count ?? 0
        let cooldownCount = (routine.cooldownExercises as? Set<Exercise>)?.count ?? 0
        
        switch workoutViewModel.currentPhase {
        case .warmup:
            return "Warm-up (\(workoutViewModel.currentExerciseIndex + 1)/\(warmupCount))"
        case .main:
            return "Main Workout (\(workoutViewModel.currentExerciseIndex + 1)/\(mainCount))"
        case .cooldown:
            return "Cool-down (\(workoutViewModel.currentExerciseIndex + 1)/\(cooldownCount))"
        }
    }
    
    // MARK: - Phase Color
    private var phaseColor: Color {
        switch workoutViewModel.currentPhase {
        case .warmup:
            return AppTheme.warmupColor
        case .main:
            return AppTheme.mainColor
        case .cooldown:
            return AppTheme.cooldownColor
        }
    }
    
    // MARK: - Workout Progress
    private var workoutProgress: CGFloat {
        let warmupCount = Float((routine.warmupExercises as? Set<Exercise>)?.count ?? 0)
        let mainCount = Float((routine.mainExercises as? Set<Exercise>)?.count ?? 0)
        let cooldownCount = Float((routine.cooldownExercises as? Set<Exercise>)?.count ?? 0)
        
        let total = warmupCount + mainCount + cooldownCount
        guard total > 0 else { return 0 }
        
        var completed: Float = 0
        
        switch workoutViewModel.currentPhase {
        case .warmup:
            completed = Float(workoutViewModel.currentExerciseIndex)
        case .main:
            completed = warmupCount + Float(workoutViewModel.currentExerciseIndex)
        case .cooldown:
            completed = warmupCount + mainCount + Float(workoutViewModel.currentExerciseIndex)
        }
        
        return CGFloat(completed / total)
    }
}

#Preview {
    WorkoutActiveView(
        routine: DataController.preview.createSampleWorkoutRoutine(),
        workoutViewModel: WorkoutViewModel()
    )
    .environmentObject(HealthManager.shared)
    .environmentObject(DataController.preview)
}

// MARK: - Updated Preview Data
extension DataController {
    func createSampleWorkoutRoutine() -> WorkoutRoutine {
        let context = container.viewContext
        
        // Create sample routine
        let routine = WorkoutRoutine(context: context)
        routine.uuid = UUID()
        // FIXED: use "string" attribute for the routine name
        routine.name = "Full Body Workout"
        routine.createdDate = Date()
        
        // Create a few sample exercises
        let pushup = Exercise(context: context)
        pushup.uuid = UUID()
        pushup.name = "Push-up"
        pushup.muscleGroup = "Chest"
        pushup.category = "Strength"
        pushup.warmupOrder = 0
        
        let squat = Exercise(context: context)
        squat.uuid = UUID()
        squat.name = "Squat"
        squat.muscleGroup = "Legs"
        squat.category = "Strength"
        squat.mainOrder = 0
        
        let stretch = Exercise(context: context)
        stretch.uuid = UUID()
        stretch.name = "Hamstring Stretch"
        stretch.muscleGroup = "Legs"
        stretch.category = "Flexibility"
        stretch.cooldownOrder = 0
        
        // FIXED: Manually insert these exercises into the routine's relationships.
        // e.g. Warmup
        var warmupSet = routine.warmupExercises as? Set<Exercise> ?? []
        warmupSet.insert(pushup)
        routine.warmupExercises = NSSet(set: warmupSet)
        
        // Main
        var mainSet = routine.mainExercises as? Set<Exercise> ?? []
        mainSet.insert(squat)
        routine.mainExercises = NSSet(set: mainSet)
        
        // Cooldown
        var coolSet = routine.cooldownExercises as? Set<Exercise> ?? []
        coolSet.insert(stretch)
        routine.cooldownExercises = NSSet(set: coolSet)
        
        return routine
    }
}
