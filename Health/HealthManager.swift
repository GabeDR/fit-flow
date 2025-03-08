//
//  HealthManager.swift
//  FitFlow
//
//  Created by Gabriel Duarte on 3/6/25.
//

import Foundation
import HealthKit
import SwiftUI

class HealthManager: NSObject, ObservableObject {
    // MARK: - Singleton
    static let shared = HealthManager()
    
    // MARK: - HealthKit
    let healthStore = HKHealthStore()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var workoutInProgress = false
    @Published var currentHeartRate: Double = 0
    @Published var activeCaloriesBurned: Double = 0
    @Published var currentWorkoutStartDate: Date?
    @Published var workoutDuration: TimeInterval = 0
    
    // MARK: - Queries / Anchors
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var heartRateAnchor: HKQueryAnchor?
    
    private var activeEnergyQuery: HKAnchoredObjectQuery?
    private var activeEnergyAnchor: HKQueryAnchor?
    
    // Timer for updating UI “duration”
    private var workoutTimer: Timer?
    
    // HealthKit data types
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]
    
    private override init() {
        super.init()
    }
}

// MARK: - Authorization
extension HealthManager {
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success, error)
            }
        }
    }
}

// MARK: - Start / End “Workout”
extension HealthManager {
    
    /// Call this to begin tracking a workout on iOS:
    /// - Sets `workoutInProgress` = true
    /// - Resets anchors and starts queries for heart rate + active energy
    /// - Resets activeCaloriesBurned to 0
    /// - Starts a local Timer to show “duration” in your UI
    func startWorkout() {
        guard isAuthorized else {
            print("HealthKit not authorized.")
            return
        }
        
        // Clear old data
        activeCaloriesBurned = 0
        currentHeartRate = 0
        
        // Mark the time we started
        currentWorkoutStartDate = Date()
        workoutInProgress = true
        
        // Start the timer for UI
        startWorkoutTimer()
        
        // Reset anchors so we read only new samples from now on
        heartRateAnchor = nil
        activeEnergyAnchor = nil
        
        // Start queries
        startObservingHeartRate()
        startObservingActiveEnergy()
    }
    
    /// Call this to end the “workout”:
    /// - Stops queries
    /// - Creates a `HKWorkout` with your start and end time
    /// - Saves total active energy burned
    /// - Resets everything
    func endWorkout(completion: @escaping (HKWorkout?, Error?) -> Void) {
        guard workoutInProgress,
              let startDate = currentWorkoutStartDate else {
            completion(nil, nil)
            return
        }
        
        // Stop queries
        stopObservingHeartRate()
        stopObservingActiveEnergy()
        
        // Stop timer
        stopWorkoutTimer()
        
        // Prepare end date
        let endDate = Date()
        let duration = endDate.timeIntervalSince(startDate)
        
        // Build HKWorkout object
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: activeCaloriesBurned),
            totalDistance: nil,
            metadata: nil
        )
        
        // Save the workout
        healthStore.save(workout) { success, error in
            DispatchQueue.main.async {
                // Reset all state
                self.workoutInProgress = false
                self.workoutDuration = 0
                self.currentHeartRate = 0
                self.activeCaloriesBurned = 0
                self.currentWorkoutStartDate = nil
                
                completion(workout, error)
            }
        }
    }
}

// MARK: - Observing Heart Rate & Active Energy
extension HealthManager {
    
    private func startObservingHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        let query = HKAnchoredObjectQuery(type: heartRateType,
                                          predicate: nil,
                                          anchor: heartRateAnchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil else { return }
            self.heartRateAnchor = newAnchor
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                self.processHeartRateSamples(quantitySamples)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil else { return }
            self.heartRateAnchor = newAnchor
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                self.processHeartRateSamples(quantitySamples)
            }
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func stopObservingHeartRate() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
    }
    
    private func processHeartRateSamples(_ samples: [HKQuantitySample]) {
        // Let's just set currentHeartRate to the most recent sample
        // Heart rate is in count/min
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let lastSample = samples.last else { return }
        
        let value = lastSample.quantity.doubleValue(for: unit)
        DispatchQueue.main.async {
            self.currentHeartRate = value
        }
    }
    
    private func startObservingActiveEnergy() {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let query = HKAnchoredObjectQuery(type: energyType,
                                          predicate: nil,
                                          anchor: activeEnergyAnchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil else { return }
            self.activeEnergyAnchor = newAnchor
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                self.processEnergySamples(quantitySamples)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, error == nil else { return }
            self.activeEnergyAnchor = newAnchor
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                self.processEnergySamples(quantitySamples)
            }
        }
        
        healthStore.execute(query)
        activeEnergyQuery = query
    }
    
    private func stopObservingActiveEnergy() {
        if let query = activeEnergyQuery {
            healthStore.stop(query)
        }
        activeEnergyQuery = nil
    }
    
    private func processEnergySamples(_ samples: [HKQuantitySample]) {
        let unit = HKUnit.kilocalorie()
        
        // Add up all new samples to running total
        let addedEnergy = samples.reduce(0.0) { partial, sample in
            partial + sample.quantity.doubleValue(for: unit)
        }
        
        DispatchQueue.main.async {
            self.activeCaloriesBurned += addedEnergy
        }
    }
}

// MARK: - Timer for Duration
extension HealthManager {
    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                            repeats: true) { [weak self] _ in
            guard let self = self,
                  let startDate = self.currentWorkoutStartDate else { return }
            self.workoutDuration = Date().timeIntervalSince(startDate)
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
}

// MARK: - Additional Utility
extension HealthManager {
    /// Save a historical workout, e.g. if you have your own start/end times.
    func saveWorkout(startDate: Date,
                     endDate: Date,
                     workoutType: HKWorkoutActivityType = .traditionalStrengthTraining,
                     energyBurned: Double? = nil,
                     completion: @escaping (Bool, Error?) -> Void) {
        
        let workout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: energyBurned != nil
                ? HKQuantity(unit: .kilocalorie(), doubleValue: energyBurned!)
                : nil,
            totalDistance: nil,
            metadata: nil
        )
        
        healthStore.save(workout) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    /// Retrieves recent workouts (past 30 days) of any HKWorkoutActivityType.
    func getWorkouts(limit: Int = 10, completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: limit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                guard let workouts = samples as? [HKWorkout], error == nil else {
                    completion(nil, error)
                    return
                }
                completion(workouts, nil)
            }
        }
        
        healthStore.execute(query)
    }
}
