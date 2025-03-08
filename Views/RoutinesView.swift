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
                        routineName = routine.name!
                        routineNotes = routine.notes!
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

// MARK: - Minimal RoutineDetailView
struct RoutineDetailView: View {
    let routine: WorkoutRoutine
    let viewModel: RoutineViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text(routine.name ?? "Unknown Routine")
                .font(.title)
            
            Text("Here is where you'd show routine details, exercises, etc.")
                .font(.body)
        }
        .padding()
        .navigationTitle("Routine Detail")
    }
}

#Preview {
    RoutinesView()
        .environmentObject(DataController.preview)
}
