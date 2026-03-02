import SwiftUI

struct CheckInView: View {
    let pactId: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var progress: Int = 50
    @State private var note: String = ""
    
    private var pact: Pact? {
        pactStore.getPact(id: pactId)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if let pact = pact {
                    mainContent(pact: pact)
                } else {
                    notFoundView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
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
    
    // MARK: - Main Content
    
    private func mainContent(pact: Pact) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header area
                headerArea(pact: pact)
                
                // Slider section
                sliderSection
                
                // Note section
                noteSection
                
                // Submit button
                submitButton
            }
            .padding(22)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Header Area
    
    private func headerArea(pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.indigoGlow)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.indigo)
            }
            .padding(.bottom, 16)
            
            Text(pact.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.3)
                .padding(.bottom, 4)
            
            Text("How are you progressing?")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.bottom, 28)
    }
    
    // MARK: - Slider Section
    
    private var sliderSection: some View {
        VStack(spacing: 0) {
            Text("\(progress)%")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(AppColors.gold)
                .tracking(-1)
                .padding(.bottom, 16)
            
            ProgressBar(progress: Double(progress), height: 6, color: AppColors.gold)
            
            // Quick buttons
            HStack(spacing: 6) {
                ForEach([0, 25, 50, 75, 100], id: \.self) { value in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            progress = value
                        }
                    } label: {
                        Text("\(value)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(progress == value ? AppColors.gold : AppColors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(progress == value ? AppColors.goldGlowStrong : AppColors.surfaceHighlight)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(progress == value ? AppColors.goldMuted : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 18)
        }
        .padding(20)
        .background(AppColors.surface)
        .cornerRadius(16)
        .padding(.bottom, 28)
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("NOTE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.6)
            
            Text("Optional")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textMuted)
                .padding(.bottom, 8)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $note)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 100)
                
                if note.isEmpty {
                    Text("Reflect on your progress...")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .background(AppColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button {
            handleSubmit()
        } label: {
            Text("Save Check-in")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.indigo)
                .cornerRadius(14)
                .shadow(color: AppColors.indigo.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        Text("Pact not found.")
            .font(.system(size: 16))
            .foregroundColor(AppColors.textSecondary)
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        pactStore.addCheckIn(
            pactId: pactId,
            progress: progress,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dismiss()
    }
}

#Preview {
    CheckInView(pactId: "test")
        .environmentObject(PactStore())
}
