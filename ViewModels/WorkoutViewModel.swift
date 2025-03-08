//
//  WorkoutViewModel.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import Foundation
import Combine
import CoreData
import HealthKit
import SwiftUI

class WorkoutViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var currentRoutine: WorkoutRoutine?
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSetIndex: Int = 0
    @Published var currentRestTimer: Int = 0
    @Published var isResting: Bool = false
    @Published var workoutInProgress: Bool = false
    @Published var workoutCompleted: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var exerciseCompletionState: [String: [Int: Bool]] = [:]
    
    // Timers
    private var restTimer: Timer?
    private var workoutTimer: Timer?
    private var workoutStartTime: Date?
    
    // Exercise arrays for each phase
    private var warmupExercises: [Exercise] = []
    private var mainExercises: [Exercise] = []
    private var cooldownExercises: [Exercise] = []
    
    // Current completedWorkout for saving to Core Data
    private var completedWorkout: CompletedWorkout?
    
    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Data controller reference
    private let dataController = DataController.shared
    
    // HealthKit manager reference
    private let healthManager = HealthManager.shared
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to HealthManager's workoutInProgress
        healthManager.$workoutInProgress
            .sink { [weak self] inProgress in
                self?.workoutInProgress = inProgress
            }
            .store(in: &cancellables)
    }
    
    // Start a workout with the given routine
    func startWorkout(with routine: WorkoutRoutine) {
        // Reset state
        resetWorkoutState()
        
        // Set current routine
        currentRoutine = routine
        
        // Extract exercises
        warmupExercises = routine.warmupExercisesArray
        mainExercises   = routine.mainExercisesArray
        cooldownExercises = routine.cooldownExercisesArray
        
        // Start with warmup phase
        currentPhase = .warmup
        currentExerciseIndex = 0
        
        // Initialize completion state
        initializeCompletionState()
        
        // Record workout start time
        workoutStartTime = Date()
        
        // Create a new CompletedWorkout entity
        let context = dataController.container.viewContext
        completedWorkout = CompletedWorkout(context: context)
        completedWorkout?.uuid = UUID()
        completedWorkout?.startDate = Date()
        completedWorkout?.routine = routine
        
        // Start the workout timer
        startWorkoutTimer()
        
        // Start HealthKit workout session
        healthManager.startWorkout()
        
        // Mark workout as in progress
        workoutInProgress = true
    }
    
    // Initialize the completion state tracking dictionary
    private func initializeCompletionState() {
        exerciseCompletionState = [:]
        
        // Add warmup exercises
        for (index, exercise) in warmupExercises.enumerated() {
            if let setGroup = exercise.setGroupsArray.first {
                let setCount = Int(setGroup.targetSets)
                let key = "\(WorkoutPhase.warmup.rawValue)_\(index)"
                exerciseCompletionState[key] =
                    Dictionary(uniqueKeysWithValues: (0..<setCount).map { ($0, false) })
            }
        }
        
        // Add main exercises
        for (index, exercise) in mainExercises.enumerated() {
            if let setGroup = exercise.setGroupsArray.first {
                let setCount = Int(setGroup.targetSets)
                let key = "\(WorkoutPhase.main.rawValue)_\(index)"
                exerciseCompletionState[key] =
                    Dictionary(uniqueKeysWithValues: (0..<setCount).map { ($0, false) })
            }
        }
        
        // Add cooldown exercises
        for (index, exercise) in cooldownExercises.enumerated() {
            if let setGroup = exercise.setGroupsArray.first {
                let setCount = Int(setGroup.targetSets)
                let key = "\(WorkoutPhase.cooldown.rawValue)_\(index)"
                exerciseCompletionState[key] =
                    Dictionary(uniqueKeysWithValues: (0..<setCount).map { ($0, false) })
            }
        }
    }
    
    // Reset the workout state
    private func resetWorkoutState() {
        currentPhase = .warmup
        currentExerciseIndex = 0
        currentSetIndex = 0
        currentRestTimer = 0
        isResting = false
        workoutInProgress = false
        workoutCompleted = false
        elapsedTime = 0
        exerciseCompletionState = [:]
        
        stopRestTimer()
        stopWorkoutTimer()
        
        workoutStartTime = nil
        completedWorkout = nil
    }
    
    // Start the workout timer
    private func startWorkoutTimer() {
        stopWorkoutTimer() // Stop any existing timer
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            self.elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    // Stop the workout timer
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    // Complete the current set and move to the next
    func completeCurrentSet() {
        guard let _ = currentRoutine else { return }
        
        // Mark current set as completed
        let phaseKey = "\(currentPhase.rawValue)_\(currentExerciseIndex)"
        exerciseCompletionState[phaseKey]?[currentSetIndex] = true
        
        // Record the completed set in Core Data
        recordCompletedSet()
        
        // Get current exercise and set group
        let currentExercise = getCurrentExercise()
        let setGroup = currentExercise?.setGroupsArray.first
        
        // Check if there are more sets for this exercise
        if let setGroup = setGroup, currentSetIndex < setGroup.targetSets - 1 {
            // Move to next set
            currentSetIndex += 1
            
            // Start rest timer if not the last set
            startRestTimer(seconds: Int(setGroup.restBetweenSets))
        } else {
            // Finished all sets for this exercise
            currentSetIndex = 0
            // Move to next exercise or phase
            moveToNextExerciseOrPhase()
        }
    }
    
    // Move to the next exercise or phase
    private func moveToNextExerciseOrPhase() {
        switch currentPhase {
        case .warmup:
            if currentExerciseIndex < warmupExercises.count - 1 {
                currentExerciseIndex += 1
            } else {
                currentPhase = .main
                currentExerciseIndex = 0
            }
            
        case .main:
            if currentExerciseIndex < mainExercises.count - 1 {
                currentExerciseIndex += 1
            } else {
                currentPhase = .cooldown
                currentExerciseIndex = 0
            }
            
        case .cooldown:
            if currentExerciseIndex < cooldownExercises.count - 1 {
                currentExerciseIndex += 1
            } else {
                // Workout completed
                completeWorkout()
            }
        }
    }
    
    // Skip the current exercise
    func skipCurrentExercise() {
        currentSetIndex = 0
        moveToNextExerciseOrPhase()
    }
    
    // Skip the current phase
    func skipCurrentPhase() {
        currentSetIndex = 0
        
        switch currentPhase {
        case .warmup:
            currentPhase = .main
            currentExerciseIndex = 0
        case .main:
            currentPhase = .cooldown
            currentExerciseIndex = 0
        case .cooldown:
            completeWorkout()
        }
    }
    
    // Start the rest timer
    private func startRestTimer(seconds: Int) {
        stopRestTimer()
        
        currentRestTimer = seconds
        isResting = true
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.currentRestTimer > 0 {
                self.currentRestTimer -= 1
            } else {
                self.isResting = false
                timer.invalidate()
            }
        }
    }
    
    // Stop the rest timer
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
    }
    
    // Skip the rest period
    func skipRest() {
        stopRestTimer()
    }
    
    // Get the current exercise based on phase and index
    func getCurrentExercise() -> Exercise? {
        switch currentPhase {
        case .warmup:
            return warmupExercises[safe: currentExerciseIndex]
        case .main:
            return mainExercises[safe: currentExerciseIndex]
        case .cooldown:
            return cooldownExercises[safe: currentExerciseIndex]
        }
    }
    
    // Get the current exercise set group
    func getCurrentSetGroup() -> ExerciseSetGroup? {
        return getCurrentExercise()?.setGroupsArray.first
    }
    
    // Get the current exercise set
    func getCurrentSet() -> ExerciseSet? {
        return getCurrentSetGroup()?.setsArray[safe: currentSetIndex]
    }
    
    // Record a completed set in Core Data
    private func recordCompletedSet() {
        guard
            let completedWorkout = completedWorkout,
            let currentExercise = getCurrentExercise(),
            let setGroup = currentExercise.setGroupsArray.first,
            let currentSet = setGroup.setsArray[safe: currentSetIndex]
        else {
            return
        }
        
        let context = dataController.container.viewContext
        
        // Find or create completed set group
        let fetchRequest: NSFetchRequest<CompletedSetGroup> = CompletedSetGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "workout == %@ AND template.exercise == %@",
            completedWorkout,
            currentExercise
        )
        
        var completedSetGroup: CompletedSetGroup
        do {
            let results = try context.fetch(fetchRequest)
            if let existingGroup = results.first {
                completedSetGroup = existingGroup
            } else {
                completedSetGroup = CompletedSetGroup(context: context)
                completedSetGroup.uuid = UUID()
                completedSetGroup.workout = completedWorkout
                completedSetGroup.template = setGroup
            }
        } catch {
            print("Error fetching completed set group: \(error.localizedDescription)")
            // Create a new group if fetching failed
            completedSetGroup = CompletedSetGroup(context: context)
            completedSetGroup.uuid = UUID()
            completedSetGroup.workout = completedWorkout
            completedSetGroup.template = setGroup
        }
        
        // Create completed set
        let completedSet = CompletedSet(context: context)
        completedSet.uuid = UUID()
        completedSet.template = currentSet
        completedSet.completedReps = currentSet.targetReps
        completedSet.completedWeight = currentSet.targetWeight
        completedSet.completedDuration = currentSet.targetDuration
        completedSet.performedDate = Date()
        completedSet.setGroup = completedSetGroup
        
        // Save context
        dataController.save()
    }
    
    // Complete the workout
    func completeWorkout() {
        guard let completedWorkout = completedWorkout else { return }
        
        // Stop timers
        stopWorkoutTimer()
        stopRestTimer()
        
        // Record end time
        let endDate = Date()
        completedWorkout.endDate = endDate
        
        // Save to Core Data
        dataController.save()
        
        // End HealthKit workout
        healthManager.endWorkout { workout, error in
            if let error = error {
                print("Error ending HealthKit workout: \(error.localizedDescription)")
            }
            
            // If we have a valid HKWorkout
            if let workout = workout {
                print("HealthKit workout completed: \(workout)")
            }
        }
        
        // Mark workout as completed
        workoutCompleted = true
        workoutInProgress = false
        
        // Reset state
        resetWorkoutState()
    }
    
    // Cancel the workout
    func cancelWorkout() {
        guard workoutInProgress else { return }
        
        // Stop timers
        stopWorkoutTimer()
        stopRestTimer()
        
        // End HealthKit workout
        healthManager.endWorkout { _, _ in }
        
        // Delete the workout from Core Data
        if let completedWorkout = completedWorkout {
            dataController.delete(completedWorkout)
        }
        
        // Reset state
        resetWorkoutState()
    }
    
    // Format time as MM:SS
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Array Extension for Safe Indexing
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Model Extensions
//
// These assume your Core Data entity "WorkoutRoutine" has NSSet relationships
// named "warmupExercises", "mainExercises", "cooldownExercises" to the "Exercise" entity.
// Similarly, "Exercise" has an NSSet "setGroups" -> "ExerciseSetGroup",
// and "ExerciseSetGroup" has an NSSet "sets" -> "ExerciseSet".
//

extension WorkoutRoutine {
    var warmupExercisesArray: [Exercise] {
        // Assuming "warmupExercises" is an NSSet of Exercises
        let set = warmupExercises as? Set<Exercise> ?? []
        // Optional: sort by "warmupOrder" or any other property if you have one
        // For example:
        // return set.sorted { $0.warmupOrder < $1.warmupOrder }
        return Array(set)
    }
    
    var mainExercisesArray: [Exercise] {
        let set = mainExercises as? Set<Exercise> ?? []
        return Array(set)
    }
    
    var cooldownExercisesArray: [Exercise] {
        let set = cooldownExercises as? Set<Exercise> ?? []
        return Array(set)
    }
}

extension Exercise {
    var setGroupsArray: [ExerciseSetGroup] {
        let set = setGroups as? Set<ExerciseSetGroup> ?? []
        return Array(set)
    }
}

extension ExerciseSetGroup {
    var setsArray: [ExerciseSet] {
        let set = sets as? Set<ExerciseSet> ?? []
        return Array(set)
    }
}
