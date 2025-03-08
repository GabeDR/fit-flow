//
//  RoutineViewModel.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import Foundation
import CoreData
import Combine

class RoutineViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var routines: [WorkoutRoutine] = []
    @Published var exercises: [Exercise] = []
    
    // Our filtered (searched) exercises
    @Published var searchText: String = ""
    @Published var filteredExercises: [Exercise] = []
    
    @Published var selectedMuscleGroup: MuscleGroup?
    @Published var selectedCategory: ExerciseCategory?
    @Published var selectedEquipment: EquipmentType?
    
    private let dataController = DataController.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchPublisher()
        fetchRoutines()
        fetchExercises()
    }
    
    // MARK: - Reactive Search Publisher
    private func setupSearchPublisher() {
        Publishers.CombineLatest4(
            $searchText,
            $selectedMuscleGroup,
            $selectedCategory,
            $selectedEquipment
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] (searchText, muscleGroup, category, equipment) in
            self?.filterExercises(searchText: searchText,
                                  muscleGroup: muscleGroup,
                                  category: category,
                                  equipment: equipment)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Fetch Routines
    func fetchRoutines() {
        let request: NSFetchRequest<WorkoutRoutine> = WorkoutRoutine.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            routines = try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching routines: \(error.localizedDescription)")
            routines = []
        }
    }
    
    // MARK: - Fetch Exercises
    func fetchExercises() {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            exercises = try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching exercises: \(error.localizedDescription)")
            exercises = []
        }
        
        // Once we have them, apply filter
        filterExercises(searchText: searchText,
                        muscleGroup: selectedMuscleGroup,
                        category: selectedCategory,
                        equipment: selectedEquipment)
    }
    
    // MARK: - Filtering
    private func filterExercises(searchText: String,
                                 muscleGroup: MuscleGroup?,
                                 category: ExerciseCategory?,
                                 equipment: EquipmentType?)
    {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        filteredExercises = exercises.filter { exercise in
            let name = exercise.name?.lowercased() ?? ""
            let desc = exercise.descrip?.lowercased() ?? ""
            let mg = exercise.muscleGroup ?? ""
            let cat = exercise.category ?? ""
            let eq = exercise.equipment ?? ""
            
            let matchesSearch = trimmedSearchText.isEmpty
                || name.contains(trimmedSearchText)
                || desc.contains(trimmedSearchText)
            
            let matchesMuscleGroup = (muscleGroup == nil) || (muscleGroup?.rawValue == mg)
            let matchesCategory = (category == nil) || (category?.rawValue == cat)
            let matchesEquipment = (equipment == nil) || (equipment?.rawValue == eq)
            
            return matchesSearch && matchesMuscleGroup && matchesCategory && matchesEquipment
        }
    }
    
    // MARK: - Create / Delete / Update Routines
    func createRoutine(name: String, notes: String = "") -> WorkoutRoutine {
        let context = dataController.container.viewContext
        let routine = WorkoutRoutine(context: context)
        
        routine.uuid = UUID()
        routine.name = name
        routine.notes = notes
        routine.createdDate = Date()
        
        dataController.save()
        fetchRoutines()
        
        return routine
    }
    
    func deleteRoutine(_ routine: WorkoutRoutine) {
        dataController.delete(routine)
        fetchRoutines()
    }
    
    func updateRoutine(_ routine: WorkoutRoutine, name: String, notes: String) {
        routine.name = name
        routine.notes = notes
        
        dataController.save()
        fetchRoutines()
    }
    
    // MARK: - Add Exercise to Routine
    func addExerciseToRoutine(_ exercise: Exercise,
                              to routine: WorkoutRoutine,
                              phase: WorkoutPhase,
                              sets: Int16 = 3,
                              reps: Int16 = 10,
                              weight: Double = 0,
                              duration: Int16 = 0)
    {
        let context = dataController.container.viewContext
        
        // Create set group
        let setGroup = ExerciseSetGroup(context: context)
        setGroup.uuid = UUID()
        setGroup.targetSets = sets
        setGroup.restBetweenSets = 60
        setGroup.exercise = exercise
        
        // Create individual sets
        for i in 0..<sets {
            let newSet = ExerciseSet(context: context)
            newSet.uuid = UUID()
            newSet.order = Int16(i)
            newSet.targetReps = reps
            
            if weight > 0 {
                newSet.targetWeight = weight
            }
            if duration > 0 {
                newSet.targetDuration = duration
            }
            newSet.setGroup = setGroup
        }
        
        // Compute the next order in the relevant phase
        var order: Int32 = 0
        
        switch phase {
        case .warmup:
            let warmupSet = routine.warmupExercises as? Set<Exercise> ?? []
            let orders = warmupSet.map { $0.warmupOrder }
            order = (orders.max() ?? -1) + 1
            
            exercise.warmupOrder = order
            // Insert into warmupExercises
            let updatedSet = warmupSet.union([exercise])
            // **Fixed**: Now assigning NSSet to a to-many relationship
            routine.warmupExercises = NSSet(set: updatedSet)
            
        case .main:
            let mainSet = routine.mainExercises as? Set<Exercise> ?? []
            let orders = mainSet.map { $0.mainOrder }
            order = (orders.max() ?? -1) + 1
            
            exercise.mainOrder = order
            let updatedSet = mainSet.union([exercise])
            // **Fixed**: Must also be a to-many
            routine.mainExercises = NSSet(set: updatedSet)
            
        case .cooldown:
            let coolSet = routine.cooldownExercises as? Set<Exercise> ?? []
            let orders = coolSet.map { $0.cooldownOrder }
            order = (orders.max() ?? -1) + 1
            
            exercise.cooldownOrder = order
            let updatedSet = coolSet.union([exercise])
            routine.cooldownExercises = NSSet(set: updatedSet)
        }
        
        dataController.save()
    }
    
    // MARK: - Remove Exercise from Routine
    func removeExerciseFromRoutine(_ exercise: Exercise,
                                   from routine: WorkoutRoutine,
                                   phase: WorkoutPhase)
    {
        switch phase {
        case .warmup:
            if let warmupSet = routine.warmupExercises as? Set<Exercise> {
                let newSet = warmupSet.subtracting([exercise])
                routine.warmupExercises = NSSet(set: newSet)
            }
        case .main:
            if let mainSet = routine.mainExercises as? Set<Exercise> {
                let newSet = mainSet.subtracting([exercise])
                routine.mainExercises = NSSet(set: newSet)
            }
        case .cooldown:
            if let coolSet = routine.cooldownExercises as? Set<Exercise> {
                let newSet = coolSet.subtracting([exercise])
                routine.cooldownExercises = NSSet(set: newSet)
            }
        }
        
        dataController.save()
    }
    
    // MARK: - Reorder Exercises
    func reorderExercises(in routine: WorkoutRoutine,
                          phase: WorkoutPhase,
                          fromIndex: Int,
                          toIndex: Int)
    {
        var exercisesArray: [Exercise] = []
        
        switch phase {
        case .warmup:
            exercisesArray = (routine.warmupExercises as? Set<Exercise> ?? []).sorted {
                $0.warmupOrder < $1.warmupOrder
            }
        case .main:
            exercisesArray = (routine.mainExercises as? Set<Exercise> ?? []).sorted {
                $0.mainOrder < $1.mainOrder
            }
        case .cooldown:
            exercisesArray = (routine.cooldownExercises as? Set<Exercise> ?? []).sorted {
                $0.cooldownOrder < $1.cooldownOrder
            }
        }
        
        guard fromIndex >= 0,
              fromIndex < exercisesArray.count,
              toIndex >= 0,
              toIndex < exercisesArray.count
        else { return }
        
        let exercise = exercisesArray.remove(at: fromIndex)
        exercisesArray.insert(exercise, at: toIndex)
        
        for (newIndex, ex) in exercisesArray.enumerated() {
            switch phase {
            case .warmup:
                ex.warmupOrder = Int32(newIndex)
            case .main:
                ex.mainOrder = Int32(newIndex)
            case .cooldown:
                ex.cooldownOrder = Int32(newIndex)
            }
        }
        
        dataController.save()
    }
    
    // MARK: - Create / Update Exercises
    func createExercise(name: String,
                        description: String = "",
                        category: ExerciseCategory = .strength,
                        muscleGroup: MuscleGroup = .other,
                        equipment: EquipmentType = .none,
                        instructions: String = "") -> Exercise
    {
        let context = dataController.container.viewContext
        let exercise = Exercise(context: context)
        
        exercise.uuid = UUID()
        exercise.name = name
        exercise.descrip = description
        exercise.category = category.rawValue
        exercise.muscleGroup = muscleGroup.rawValue
        exercise.equipment = equipment.rawValue
        exercise.instructionsText = instructions
        exercise.isCustom = true
        
        dataController.save()
        fetchExercises()
        
        return exercise
    }
    
    func updateExercise(_ exercise: Exercise,
                        name: String,
                        description: String,
                        category: ExerciseCategory,
                        muscleGroup: MuscleGroup,
                        equipment: EquipmentType,
                        instructions: String)
    {
        exercise.name = name
        exercise.descrip = description
        exercise.category = category.rawValue
        exercise.muscleGroup = muscleGroup.rawValue
        exercise.equipment = equipment.rawValue
        exercise.instructionsText = instructions
        
        dataController.save()
        fetchExercises()
    }
    
    // MARK: - Scheduling Routines
    func getRoutinesForDay(_ dayOfWeek: Int) -> [WorkoutRoutine] {
        let request: NSFetchRequest<ScheduleDay> = ScheduleDay.fetchRequest()
        request.predicate = NSPredicate(format: "dayOfWeek == %d", dayOfWeek)
        
        do {
            let scheduleDays = try dataController.container.viewContext.fetch(request)
            if let scheduleDay = scheduleDays.first,
               let routinesSet = scheduleDay.routines as? Set<WorkoutRoutine>
            {
                return Array(routinesSet)
            }
        } catch {
            print("Error fetching schedule days: \(error.localizedDescription)")
        }
        
        return []
    }
    
    func scheduleRoutine(_ routine: WorkoutRoutine, for dayOfWeek: Int) {
        let context = dataController.container.viewContext
        
        let request: NSFetchRequest<ScheduleDay> = ScheduleDay.fetchRequest()
        request.predicate = NSPredicate(format: "dayOfWeek == %d", dayOfWeek)
        
        do {
            let scheduleDays = try context.fetch(request)
            let scheduleDay: ScheduleDay
            
            if let existingDay = scheduleDays.first {
                scheduleDay = existingDay
            } else {
                scheduleDay = ScheduleDay(context: context)
                scheduleDay.uuid = UUID()
                scheduleDay.dayOfWeek = Int16(dayOfWeek)
            }
            
            let set = scheduleDay.routines as? Set<WorkoutRoutine> ?? []
            scheduleDay.routines = NSSet(set: set.union([routine]))
            
            dataController.save()
            
        } catch {
            print("Error scheduling routine: \(error.localizedDescription)")
        }
    }
    
    func unscheduleRoutine(_ routine: WorkoutRoutine, from dayOfWeek: Int) {
        let context = dataController.container.viewContext
        
        let request: NSFetchRequest<ScheduleDay> = ScheduleDay.fetchRequest()
        request.predicate = NSPredicate(format: "dayOfWeek == %d", dayOfWeek)
        
        do {
            let scheduleDays = try context.fetch(request)
            if let scheduleDay = scheduleDays.first,
               let routinesSet = scheduleDay.routines as? Set<WorkoutRoutine>
            {
                let newSet = routinesSet.subtracting([routine])
                scheduleDay.routines = NSSet(set: newSet)
                
                // If no more routines remain, delete the schedule day
                if newSet.isEmpty {
                    context.delete(scheduleDay)
                }
                
                dataController.save()
            }
        } catch {
            print("Error unscheduling routine: \(error.localizedDescription)")
        }
    }
    
    func fetchScheduleDays() -> [ScheduleDay] {
        let request: NSFetchRequest<ScheduleDay> = ScheduleDay.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dayOfWeek", ascending: true)]
        
        do {
            return try dataController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching schedule days: \(error.localizedDescription)")
            return []
        }
    }
}
