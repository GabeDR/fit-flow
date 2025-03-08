//
//  Models.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import Foundation
import CoreData

// MARK: - Enum Definitions

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case abs = "Abs"
    case legs = "Legs"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"
    case other = "Other"
    
    var id: String { self.rawValue }
}

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case balance = "Balance"
    case plyometric = "Plyometric"
    case other = "Other"
    
    var id: String { self.rawValue }
}

enum EquipmentType: String, CaseIterable, Identifiable {
    case none = "None"
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case kettlebell = "Kettlebell"
    case resistanceBands = "Resistance Bands"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case other = "Other"
    
    var id: String { self.rawValue }
}

// MARK: - Model Extensions
// These are commented out temporarily until Core Data model entities are generated

/*
extension WorkoutRoutine {
    var wrappedName: String {
        name ?? "Unnamed Routine"
    }
    
    var wrappedNotes: String {
        notes ?? ""
    }
    
    var warmupExercisesArray: [Exercise] {
        let set = warmupExercises as? Set<Exercise> ?? []
        return set.sorted {
            $0.warmupOrder < $1.warmupOrder
        }
    }
    
    var mainExercisesArray: [Exercise] {
        let set = mainExercises as? Set<Exercise> ?? []
        return set.sorted {
            $0.mainOrder < $1.mainOrder
        }
    }
    
    var cooldownExercisesArray: [Exercise] {
        let set = cooldownExercises as? Set<Exercise> ?? []
        return set.sorted {
            $0.cooldownOrder < $1.cooldownOrder
        }
    }
    
    var completedWorkoutsArray: [CompletedWorkout] {
        let set = completedWorkouts as? Set<CompletedWorkout> ?? []
        return set.sorted {
            $0.startDate ?? Date() > $1.startDate ?? Date()
        }
    }
    
    var scheduledDaysArray: [ScheduleDay] {
        let set = scheduledDays as? Set<ScheduleDay> ?? []
        return set.sorted {
            $0.dayOfWeek < $1.dayOfWeek
        }
    }
}

extension Exercise {
    var wrappedName: String {
        name ?? "Unnamed Exercise"
    }
    
    var wrappedDescription: String {
        description ?? ""
    }
    
    var wrappedInstructionsText: String {
        instructionsText ?? "No instructions available"
    }
    
    var muscleGroupEnum: MuscleGroup {
        MuscleGroup(rawValue: muscleGroup ?? "Other") ?? .other
    }
    
    var categoryEnum: ExerciseCategory {
        ExerciseCategory(rawValue: category ?? "Other") ?? .other
    }
    
    var equipmentEnum: EquipmentType {
        EquipmentType(rawValue: equipment ?? "None") ?? .none
    }
    
    var setGroupsArray: [ExerciseSetGroup] {
        let set = setGroups as? Set<ExerciseSetGroup> ?? []
        return set.sorted {
            if $0.exercise?.warmupOrder == $1.exercise?.warmupOrder {
                return ($0.exercise?.name ?? "") < ($1.exercise?.name ?? "")
            }
            return $0.exercise?.warmupOrder ?? 0 < $1.exercise?.warmupOrder ?? 0
        }
    }
}

extension ExerciseSetGroup {
    var setsArray: [ExerciseSet] {
        let set = sets as? Set<ExerciseSet> ?? []
        return set.sorted {
            $0.order < $1.order
        }
    }
    
    var wrappedExerciseName: String {
        exercise?.name ?? "Unknown Exercise"
    }
}

extension ExerciseSet {
    var wrappedNotes: String {
        notes ?? ""
    }
}

extension CompletedWorkout {
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate ?? Date())
    }
    
    var duration: TimeInterval {
        guard let end = endDate, let start = startDate else { return 0 }
        return end.timeIntervalSince(start)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    var completedSetGroupsArray: [CompletedSetGroup] {
        let set = completedSetGroups as? Set<CompletedSetGroup> ?? []
        return set.sorted {
            $0.template?.exercise?.warmupOrder ?? 0 < $1.template?.exercise?.warmupOrder ?? 0
        }
    }
}

extension CompletedSetGroup {
    var completedSetsArray: [CompletedSet] {
        let set = completedSets as? Set<CompletedSet> ?? []
        return set.sorted {
            $0.template?.order ?? 0 < $1.template?.order ?? 0
        }
    }
}

extension ScheduleDay {
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[Int(dayOfWeek)]
    }
    
    var routinesArray: [WorkoutRoutine] {
        let set = routines as? Set<WorkoutRoutine> ?? []
        return set.sorted {
            $0.name ?? "" < $1.name ?? ""
        }
    }
}
*/
