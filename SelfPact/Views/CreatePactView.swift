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

                if showDatePicker {
                    datePickerModal
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity
                        ))
                        .zIndex(1)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.88), value: showDatePicker)
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        ToolbarSymbolButton(systemName: "xmark", accessibilityLabel: "Close") {
            dismiss()
        }
    }
    
    // MARK: - Header Area
    
    private var headerArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.accentGlow)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "pencil.line")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.bottom, 20)
            
            Text("Create a Goal")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1.0)
                .padding(.bottom, 10)
            
            Text("Write clearly. You’ll keep this promise unchanged once it’s locked.")
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
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.8)
                
                TextField("e.g., Run a marathon by December", text: $title)
                    .textFieldStyle(PactTextFieldStyle(hasError: errors["title"] != nil))
                    .onChange(of: title) { _, _ in errors.removeValue(forKey: "title") }

                Text("Make it specific enough to recognize progress.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                
                if let error = errors["title"] {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.error)
                }
            }
            
            // Why This Matters
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("WHY THIS COMMITMENT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
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
                        .foregroundColor(AppColors.textSecondary)
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
                        .foregroundColor(AppColors.accent)
                    
                    Text("TARGET DATE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(0.8)
                    
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }
                
                Button {
                    withAnimation {
                        showDatePicker = true
                    }
                } label: {
                    HStack {
                        Text(targetDate.formatted(.dateTime.year().month().day()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textMuted)
                            .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                    }
                    .padding(16)
                    .background(AppColors.backgroundElevated)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(errors["targetDate"] != nil ? AppColors.error : AppColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
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
            Text("Create Trial Goal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.accentStrong)
                .cornerRadius(16)
                .shadow(color: AppColors.accent.opacity(0.14), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private var datePickerModal: some View {
        GlowModal(
            title: "Choose a Target Date",
            subtitle: "Pick the day this commitment should be reviewed.",
            onDismiss: {
                withAnimation {
                    showDatePicker = false
                }
            }
        ) {
            VStack(spacing: 18) {
                DatePicker(
                    "",
                    selection: $targetDate,
                    in: Date().addingTimeInterval(86400)...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(AppColors.accentStrong)
                .padding(16)
                .background(AppColors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .onChange(of: targetDate) { _, _ in
                    errors.removeValue(forKey: "targetDate")
                }

                HStack(spacing: 12) {
                    Text(targetDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Button {
                        withAnimation {
                            showDatePicker = false
                        }
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(AppColors.accentStrong)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
        
        _ = pactStore.createPact(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            why: why.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : why.trimmingCharacters(in: .whitespacesAndNewlines),
            measurableTarget: measurableTarget.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : measurableTarget.trimmingCharacters(in: .whitespacesAndNewlines),
            targetDate: targetDate
        )
        
        dismiss()
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
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hasError ? AppColors.error : AppColors.border, lineWidth: 1)
            )
    }
}

#Preview {
    CreatePactView()
        .environmentObject(PactStore())
}
