//
//  DataController.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import CoreData
import Foundation

/// Simple enum to replace the ambiguous `WorkoutPhase`
enum Phase {
    case warmup
    case main
    case cooldown
}

class DataController: ObservableObject {
    // The shared data controller used by the app
    static let shared = DataController()
    
    // Core Data container
    let container: NSPersistentContainer
    
    // Preview instance for SwiftUI previews
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        // Add sample data to the preview instance
        let viewContext = controller.container.viewContext
        
        // Create sample data here
        controller.createSampleData(in: viewContext)
        
        return controller
    }()
    
    // Initialize the Core Data stack
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitFlow")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                fatalError("Failed to load Core Data: \(error.localizedDescription)")
            }
            
            // Merge policy to handle conflicts
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    // Save the Core Data context if there are changes
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    // Delete an object from Core Data
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
    
    // Create a new background context for operations that should not block the UI
    func backgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    // MARK: - Sample Data Creation
    
    func createSampleData(in context: NSManagedObjectContext) {
        // Create sample exercises
        let pushup = createExercise(in: context, name: "Push-up",
                                    descriptionText: "A classic bodyweight exercise for chest, shoulders, and triceps",
                                    category: "Strength", muscleGroup: "Chest",
                                    equipment: "Bodyweight",
                                    instructions: "Start in a high plank position with hands slightly wider than shoulder-width. Lower your body until your chest nearly touches the floor, then push back up.")
        
        let squat = createExercise(in: context, name: "Bodyweight Squat",
                                   descriptionText: "A fundamental lower body exercise",
                                   category: "Strength", muscleGroup: "Legs",
                                   equipment: "Bodyweight",
                                   instructions: "Stand with feet shoulder-width apart. Bend knees and lower hips as if sitting in a chair. Keep chest up and knees over (not past) toes.")
        
        let jogging = createExercise(in: context, name: "Jogging",
                                     descriptionText: "Light cardio exercise",
                                     category: "Cardio", muscleGroup: "Full Body",
                                     equipment: "None",
                                     instructions: "Run at a moderate pace, keeping your breathing controlled.")
        
        let stretch = createExercise(in: context, name: "Hamstring Stretch",
                                     descriptionText: "Basic stretch for hamstrings",
                                     category: "Flexibility", muscleGroup: "Legs",
                                     equipment: "None",
                                     instructions: "Sit with one leg extended and the other bent. Reach toward your toes while keeping your back straight.")
        
        // Create sample workout routine
        let fullBodyWorkout = createWorkoutRoutine(in: context, name: "Full Body Workout",
                                                   notes: "A balanced workout targeting all major muscle groups")
        
        // Add exercises to the routine (use our new Phase enum)
        addExerciseToRoutine(pushup, to: fullBodyWorkout, phase: .warmup, order: 0, sets: 2, reps: 10, context: context)
        addExerciseToRoutine(jogging, to: fullBodyWorkout, phase: .warmup, order: 1, sets: 1, reps: 1, duration: 300, context: context)
        
        addExerciseToRoutine(pushup, to: fullBodyWorkout, phase: .main, order: 0, sets: 3, reps: 12, context: context)
        addExerciseToRoutine(squat, to: fullBodyWorkout, phase: .main, order: 1, sets: 3, reps: 15, context: context)
        
        addExerciseToRoutine(stretch, to: fullBodyWorkout, phase: .cooldown, order: 0, sets: 1, reps: 1, duration: 30, context: context)
        
        // Create schedule days
        createScheduleDay(in: context, dayOfWeek: 1, routines: [fullBodyWorkout]) // Monday
        createScheduleDay(in: context, dayOfWeek: 3, routines: [fullBodyWorkout]) // Wednesday
        createScheduleDay(in: context, dayOfWeek: 5, routines: [fullBodyWorkout]) // Friday
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Error creating sample data: \(error.localizedDescription)")
        }
    }
    
    private func createExercise(in context: NSManagedObjectContext,
                                name: String,
                                descriptionText: String,
                                category: String,
                                muscleGroup: String,
                                equipment: String,
                                instructions: String) -> NSManagedObject {
        
        let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: context)
        exercise.setValue(UUID(), forKey: "uuid")
        exercise.setValue(name, forKey: "name")
        exercise.setValue(descriptionText, forKey: "descrip")
        exercise.setValue(category, forKey: "category")
        exercise.setValue(muscleGroup, forKey: "muscleGroup")
        exercise.setValue(equipment, forKey: "equipment")
        exercise.setValue(instructions, forKey: "instructionsText")
        exercise.setValue(false, forKey: "isCustom")
        return exercise
    }
    
    private func createWorkoutRoutine(in context: NSManagedObjectContext,
                                      name: String,
                                      notes: String = "") -> NSManagedObject {
        
        let routine = NSEntityDescription.insertNewObject(forEntityName: "WorkoutRoutine", into: context)
        routine.setValue(UUID(), forKey: "uuid")
        routine.setValue(name, forKey: "name")
        routine.setValue(notes, forKey: "notes")
        routine.setValue(Date(), forKey: "createdDate")
        return routine
    }
    
    private func addExerciseToRoutine(_ exercise: NSManagedObject,
                                      to routine: NSManagedObject,
                                      phase: Phase,
                                      order: Int32,
                                      sets: Int16,
                                      reps: Int16,
                                      weight: Double = 0,
                                      duration: Int16 = 0,
                                      context: NSManagedObjectContext) {
        
        // Create the set group
        let setGroup = NSEntityDescription.insertNewObject(forEntityName: "ExerciseSetGroup", into: context)
        setGroup.setValue(UUID(), forKey: "uuid")
        setGroup.setValue(sets, forKey: "targetSets")
        setGroup.setValue(60, forKey: "restBetweenSets") // Default 60 seconds rest
        setGroup.setValue(exercise, forKey: "exercise")
        
        // Create individual sets
        for i in 0..<sets {
            let set = NSEntityDescription.insertNewObject(forEntityName: "ExerciseSet", into: context)
            set.setValue(UUID(), forKey: "uuid")
            set.setValue(Int16(i), forKey: "order")
            set.setValue(reps, forKey: "targetReps")
            if weight > 0 {
                set.setValue(weight, forKey: "targetWeight")
            }
            if duration > 0 {
                set.setValue(duration, forKey: "targetDuration")
            }
            set.setValue(setGroup, forKey: "setGroup")
        }
        
        // Put the exercise into the correct phase based on our local `Phase`
        switch phase {
        case .warmup:
            exercise.setValue(order, forKey: "warmupOrder")
            // Add the exercise to the warmup exercises collection
            if let existingWarmups = routine.value(forKey: "warmupExercises") as? NSSet {
                let mutableSet = NSMutableSet(set: existingWarmups)
                mutableSet.add(exercise)
                routine.setValue(mutableSet, forKey: "warmupExercises")
            } else {
                routine.setValue(NSSet(array: [exercise]), forKey: "warmupExercises")
            }
            
        case .main:
            exercise.setValue(order, forKey: "mainOrder")
            // Add the exercise to the main exercises collection
            if let existingMains = routine.value(forKey: "mainExercises") as? NSSet {
                let mutableSet = NSMutableSet(set: existingMains)
                mutableSet.add(exercise)
                routine.setValue(mutableSet, forKey: "mainExercises")
            } else {
                routine.setValue(NSSet(array: [exercise]), forKey: "mainExercises")
            }
            
        case .cooldown:
            exercise.setValue(order, forKey: "cooldownOrder")
            // Add the exercise to the cooldown exercises collection
            if let existingCooldowns = routine.value(forKey: "cooldownExercises") as? NSSet {
                let mutableSet = NSMutableSet(set: existingCooldowns)
                mutableSet.add(exercise)
                routine.setValue(mutableSet, forKey: "cooldownExercises")
            } else {
                routine.setValue(NSSet(array: [exercise]), forKey: "cooldownExercises")
            }
        }
    }
    
    private func createScheduleDay(in context: NSManagedObjectContext,
                                   dayOfWeek: Int16,
                                   routines: [NSManagedObject]) {
        
        let scheduleDay = NSEntityDescription.insertNewObject(forEntityName: "ScheduleDay", into: context)
        scheduleDay.setValue(UUID(), forKey: "uuid")
        scheduleDay.setValue(dayOfWeek, forKey: "dayOfWeek")
        
        // Add the routines to the schedule day
        let routineSet = NSSet(array: routines)
        scheduleDay.setValue(routineSet, forKey: "routines")
    }
}
