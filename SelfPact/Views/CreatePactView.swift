import SwiftUI

struct CreatePactView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var title = ""
    @State private var why = ""
    @State private var measurableTarget = ""
    @State private var targetDate = Date().addingTimeInterval(86400 * 30) // Default 30 days from now
    @State private var showDatePicker = false
    @State private var errors: [String: String] = [:]
    @State private var navigateToPreview = false
    @State private var createdPactId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header area
                        headerArea
                        
                        // Form fields
                        formFields
                        
                        // Continue button
                        continueButton
                    }
                    .padding(22)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                if let pactId = createdPactId {
                    PreviewPactView(pactId: pactId, onDismissAll: {
                        dismiss()
                    })
                }
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surface)
                    .frame(width: 34, height: 34)
                
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    // MARK: - Header Area
    
    private var headerArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.goldGlow)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "pencil.line")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.gold)
            }
            .padding(.bottom, 20)
            
            Text("Draft a Pact")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1.0)
                .padding(.bottom, 10)
            
            Text("Write clearly. This cannot be changed once sealed.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(-0.1)
                .lineSpacing(5)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Form Fields
    
    private var formFields: some View {
        VStack(spacing: 28) {
            // Goal Title
            VStack(alignment: .leading, spacing: 10) {
                Text("GOAL TITLE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .tracking(0.8)
                
                TextField("e.g., Run a marathon by December", text: $title)
                    .textFieldStyle(PactTextFieldStyle(hasError: errors["title"] != nil))
                    .onChange(of: title) { _, _ in errors.removeValue(forKey: "title") }
                
                if let error = errors["title"] {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Why This Matters
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("WHY THIS MATTERS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)
                        .tracking(0.8)
                    
                    Text("Optional")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }
                
                TextField("What drives this commitment?", text: $why, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(PactTextFieldStyle())
            }
            
            // Measurable Target
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("MEASURABLE TARGET")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)
                        .tracking(0.8)
                    
                    Text("Optional")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }
                
                TextField("e.g., Complete 26.2 miles in under 4 hours", text: $measurableTarget)
                    .textFieldStyle(PactTextFieldStyle())
            }
            
            // Target Date
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                    
                    Text("TARGET DATE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)
                        .tracking(0.8)
                    
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.gold.opacity(0.7))
                }
                
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack {
                        Text(targetDate.formatted(.dateTime.year().month().day()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(16)
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(errors["targetDate"] != nil ? AppColors.error : AppColors.gold.opacity(0.2), lineWidth: errors["targetDate"] != nil ? 1 : 1.5)
                    )
                }
                .buttonStyle(.plain)
                
                if showDatePicker {
                    DatePicker(
                        "",
                        selection: $targetDate,
                        in: Date().addingTimeInterval(86400)...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppColors.gold)
                    .padding()
                    .background(AppColors.surface)
                    .cornerRadius(12)
                    .onChange(of: targetDate) { _, _ in
                        errors.removeValue(forKey: "targetDate")
                    }
                }
                
                if let error = errors["targetDate"] {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.error)
                }
            }
        }
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            validateAndCreate()
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.background)
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.gold)
                .cornerRadius(14)
                .shadow(color: AppColors.gold.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
    
    // MARK: - Validation
    
    private func validateAndCreate() {
        var newErrors: [String: String] = [:]
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            newErrors["title"] = "A goal title is required."
        }
        
        if targetDate <= Date() {
            newErrors["targetDate"] = "Target date must be in the future."
        }
        
        errors = newErrors
        
        if !newErrors.isEmpty { return }
        
        let pact = pactStore.createPact(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            why: why.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : why.trimmingCharacters(in: .whitespacesAndNewlines),
            measurableTarget: measurableTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : measurableTarget.trimmingCharacters(in: .whitespacesAndNewlines),
            targetDate: targetDate
        )
        
        createdPactId = pact.id
        navigateToPreview = true
    }
}

// MARK: - Custom Text Field Style

struct PactTextFieldStyle: TextFieldStyle {
    var hasError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundColor(AppColors.textPrimary)
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasError ? AppColors.error : AppColors.border, lineWidth: 1)
            )
    }
}

#Preview {
    CreatePactView()
        .environmentObject(PactStore())
}
