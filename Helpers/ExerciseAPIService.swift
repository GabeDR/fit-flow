//
//  ExerciseAPIService.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/8/25.
//

import Foundation
import Combine
import CoreData
import UIKit // Add UIKit import for UIApplication

class ExerciseAPIService {
    static let shared = ExerciseAPIService()
    
    private let baseURL = "https://api.api-ninjas.com/v1/exercises"
    private let apiKey = "Wj8nwg9MLCbLj7cTNAfPbA==7I2FhMPYY5jvfoVI"
    
    private init() {}
    
    // Fetch exercises from API with optional filters
    func fetchExercises(muscle: String? = nil, type: String? = nil, difficulty: String? = nil) {
        // Build URL with query parameters
        var urlString = baseURL
        
        if let muscle = muscle {
            let encodedMuscle = muscle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            urlString += "?muscle=\(encodedMuscle)"
        } else if let type = type {
            let encodedType = type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            urlString += "?type=\(encodedType)"
        } else if let difficulty = difficulty {
            let encodedDifficulty = difficulty.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            urlString += "?difficulty=\(encodedDifficulty)"
        }
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("API Error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let exercises = try JSONDecoder().decode([ExerciseAPIModel].self, from: data)
                print("Fetched \(exercises.count) exercises")
                DispatchQueue.main.async {
                    self.saveExercisesToCoreData(exercises: exercises)
                }
            } catch {
                print("JSON Decoding Error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        }
        
        task.resume()
    }
    
    // Import all common exercises by fetching multiple muscle groups
    func importAllExercises(completion: @escaping (Int) -> Void) {
        let muscles = ["abdominals", "biceps", "triceps", "lats", "forearms",
                      "chest", "lower_back", "middle_back", "neck", "quadriceps",
                      "hamstrings", "calves", "shoulders", "glutes"]
        
        let types = ["cardio", "olympic_weightlifting", "plyometrics",
                    "powerlifting", "strength", "stretching"]
        
        let dispatchGroup = DispatchGroup()
        var totalSaved = 0
        
        // Fetch by muscle
        for muscle in muscles {
            dispatchGroup.enter()
            
            // Modified to use completion handler
            let url = URL(string: "\(baseURL)?muscle=\(muscle)")!
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                defer { dispatchGroup.leave() }
                guard let self = self else { return }
                
                if let data = data, error == nil {
                    do {
                        let exercises = try JSONDecoder().decode([ExerciseAPIModel].self, from: data)
                        DispatchQueue.main.async {
                            let saved = self.saveExercisesToCoreData(exercises: exercises)
                            totalSaved += saved
                        }
                    } catch {
                        print("Error decoding \(muscle) exercises: \(error)")
                    }
                } else if let error = error {
                    print("Error fetching \(muscle) exercises: \(error)")
                }
            }
            task.resume()
        }
        
        // Fetch by type
        for type in types {
            dispatchGroup.enter()
            
            let url = URL(string: "\(baseURL)?type=\(type)")!
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
                defer { dispatchGroup.leave() }
                guard let self = self else { return }
                
                if let data = data, error == nil {
                    do {
                        let exercises = try JSONDecoder().decode([ExerciseAPIModel].self, from: data)
                        DispatchQueue.main.async {
                            let saved = self.saveExercisesToCoreData(exercises: exercises)
                            totalSaved += saved
                        }
                    } catch {
                        print("Error decoding \(type) exercises: \(error)")
                    }
                } else if let error = error {
                    print("Error fetching \(type) exercises: \(error)")
                }
            }
            task.resume()
        }
        
        // Notify completion
        dispatchGroup.notify(queue: .main) {
            completion(totalSaved)
        }
    }
    
    // Save exercises to Core Data, return count of added exercises
    private func saveExercisesToCoreData(exercises: [ExerciseAPIModel]) -> Int {
        // Use DataController instead of AppDelegate
        let context = DataController.shared.container.viewContext
        
        var addedCount = 0
        
        for exercise in exercises {
            // Check if exercise already exists
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Exercise")
            fetchRequest.predicate = NSPredicate(format: "name == %@", exercise.name)
            
            do {
                let count = try context.count(for: fetchRequest)
                if count == 0 {
                    // Map API data to Core Data model
                    let newExercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: context)
                    newExercise.setValue(UUID(), forKey: "uuid")
                    newExercise.setValue(exercise.name, forKey: "name")
                    newExercise.setValue(exercise.instructions, forKey: "instructionsText")
                    newExercise.setValue(mapExerciseType(exercise.type), forKey: "category")
                    newExercise.setValue(mapMuscleGroup(exercise.muscle), forKey: "muscleGroup")
                    newExercise.setValue(mapEquipment(exercise.equipment), forKey: "equipment")
                    newExercise.setValue(
                        "A \(exercise.difficulty) \(exercise.type) exercise targeting the \(exercise.muscle).",
                        forKey: "descrip"
                    )
                    newExercise.setValue(false, forKey: "isCustom")
                    
                    addedCount += 1
                }
            } catch {
                print("Error checking/saving exercise: \(error)")
            }
        }
        
        // Save context if new exercises were added
        if addedCount > 0 {
            do {
                try context.save()
                print("Added \(addedCount) exercises from API")
            } catch {
                print("Error saving context: \(error)")
            }
        }
        
        return addedCount
    }
    
    // Map API muscle names to app's format
    private func mapMuscleGroup(_ muscle: String) -> String {
        switch muscle.lowercased() {
        case "abdominals", "abductors", "adductors":
            return "Abs"
        case "biceps":
            return "Biceps"
        case "triceps":
            return "Triceps"
        case "lats", "lower_back", "middle_back", "traps":
            return "Back"
        case "chest":
            return "Chest"
        case "glutes":
            return "Glutes"
        case "hamstrings":
            return "Legs"
        case "quadriceps":
            return "Legs"
        case "calves":
            return "Calves"
        case "shoulders":
            return "Shoulders"
        case "forearms":
            return "Forearms"
        case "neck":
            return "Neck"
        default:
            return "Full Body"
        }
    }
    
    // Map API exercise types to app's categories
    private func mapExerciseType(_ type: String) -> String {
        switch type.lowercased() {
        case "cardio":
            return "Cardio"
        case "olympic_weightlifting", "powerlifting", "strength":
            return "Strength"
        case "stretching":
            return "Flexibility"
        case "plyometrics":
            return "Plyometric"
        case "strongman":
            return "Strength"
        default:
            return "Other"
        }
    }
    
    // Map equipment strings to your app's format
    private func mapEquipment(_ equipment: String) -> String {
        switch equipment.lowercased() {
        case "body only", "bodyweight", "body weight", "none":
            return "Bodyweight"
        case "barbell":
            return "Barbell"
        case "dumbbell", "dumbbells":
            return "Dumbbells"
        case "kettlebell", "kettlebells":
            return "Kettlebell"
        case "bands", "cable", "resistance bands":
            return "Resistance Bands"
        case "machine", "exercise ball", "foam roll", "medicine ball":
            return "Machine"
        default:
            return "Other"
        }
    }
}

// Model for API response
struct ExerciseAPIModel: Codable {
    let name: String
    let type: String
    let muscle: String
    let equipment: String
    let difficulty: String
    let instructions: String
}
