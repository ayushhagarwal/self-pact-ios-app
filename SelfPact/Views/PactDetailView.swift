import SwiftUI

struct PactDetailView: View {
    let pactId: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var showDeleteAlert = false
    @State private var showCheckIn = false
    @State private var showReveal = false
    
    private var pact: Pact? {
        pactStore.getPact(id: pactId)
    }
    
    var body: some View {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteButton
            }
        }
        .alert("Delete Pact", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                pactStore.deletePact(id: pactId)
                dismiss()
            }
        } message: {
            Text(pact?.isSealed == true
                 ? "This pact is sealed. Deleting it will not restore your seal credit. This action cannot be undone."
                 : "Are you sure you want to delete this draft?")
        }
        .sheet(isPresented: $showCheckIn) {
            CheckInView(pactId: pactId)
        }
        .fullScreenCover(isPresented: $showReveal) {
            RevealView(pactId: pactId)
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.errorGlow)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.error)
            }
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent(pact: Pact) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Status row
                statusRow(pact: pact)
                
                // Title
                Text(pact.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.4)
                    .lineSpacing(4)
                    .padding(.bottom, 22)
                
                // Why section
                if let why = pact.why, !why.isEmpty {
                    sectionView(label: "Why this matters", content: why)
                }
                
                // Measurable target
                if let target = pact.measurableTarget, !target.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.indigo)
                        
                        Text("MEASURABLE TARGET")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                            .tracking(0.8)
                    }
                    .padding(.bottom, 6)
                    
                    Text(target)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(6)
                        .padding(.bottom, 22)
                }
                
                // Meta card
                metaCard(pact: pact)
                
                // Progress card (for sealed pacts)
                if pact.isSealed && pact.status != .completed {
                    progressCard(pact: pact)
                }
                
                // Check-in button
                if pact.isSealed && pact.status != .completed {
                    checkInButton
                }
                
                // Reveal button
                if pact.isReady {
                    revealButton
                }
                
                // Seal button (for drafts)
                if pact.status == .draft {
                    sealButton
                }
                
                // Check-ins section
                if !pact.checkIns.isEmpty {
                    checkInsSection(pact: pact)
                }
                
                // Reflection
                if let reflection = pact.reflection, !reflection.isEmpty {
                    sectionView(label: "Reflection", content: reflection)
                }
            }
            .padding(20)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Status Row
    
    private func statusRow(pact: Pact) -> some View {
        HStack {
            if pact.isSealed && pact.status != .completed {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.gold)
                    
                    Text("Sealed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.gold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.goldGlow)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.goldMuted, lineWidth: 1)
                )
            }
            
            if pact.status == .draft {
                Text("Draft")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.surfaceHighlight)
                    .cornerRadius(8)
            }
            
            if pact.status == .completed {
                Text(outcomeText(pact.outcome))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(pact.outcome == .yes ? AppColors.success : AppColors.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(pact.outcome == .yes ? AppColors.successGlow : AppColors.surfaceHighlight)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.bottom, 14)
    }
    
    private func outcomeText(_ outcome: PactOutcome?) -> String {
        switch outcome {
        case .yes: return "Achieved"
        case .partially: return "Partially"
        case .notYet: return "Reflected"
        case nil: return ""
        }
    }
    
    // MARK: - Section View
    
    private func sectionView(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.8)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(6)
        }
        .padding(.bottom, 22)
    }
    
    // MARK: - Meta Card
    
    private func metaCard(pact: Pact) -> some View {
        VStack(spacing: 0) {
            // Target date
            metaRow(
                icon: "calendar",
                label: "Target date",
                value: pact.targetDate.formatted(.dateTime.month(.wide).day().year())
            )
            
            if pact.isSealed {
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 12)
                
                // Days remaining
                metaRow(
                    icon: "clock",
                    label: "Days remaining",
                    value: pact.isReady ? "Ready" : "\(pact.daysRemaining)",
                    valueColor: pact.isReady ? AppColors.gold : AppColors.textPrimary
                )
            }
            
            if let sealTimestamp = pact.sealTimestamp {
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 12)
                
                // Sealed on
                metaRow(
                    icon: "shield",
                    label: "Sealed on",
                    value: sealTimestamp.formatted(.dateTime.month(.abbreviated).day().year())
                )
            }
        }
        .background(AppColors.surface)
        .cornerRadius(14)
        .padding(.bottom, 14)
    }
    
    private func metaRow(icon: String, label: String, value: String, valueColor: Color = AppColors.textPrimary) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceHighlight)
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(12)
    }
    
    // MARK: - Progress Card
    
    private func progressCard(pact: Pact) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Timeline")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                
                Spacer()
                
                Text("\(Int(pact.timeProgress))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.gold)
            }
            
            ProgressBar(progress: pact.timeProgress, height: 5)
        }
        .padding(16)
        .background(AppColors.surface)
        .cornerRadius(14)
        .padding(.bottom, 14)
    }
    
    // MARK: - Action Buttons
    
    private var checkInButton: some View {
        Button {
            showCheckIn = true
        } label: {
            HStack {
                Text("Log a check-in")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.gold)
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }
    
    private var revealButton: some View {
        Button {
            showReveal = true
        } label: {
            Text("Reveal This Pact")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.background)
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.gold)
                .cornerRadius(14)
                .shadow(color: AppColors.gold.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }
    
    private var sealButton: some View {
        NavigationLink(destination: PreviewPactView(pactId: pactId)) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                
                Text("Preview & Seal")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.indigo)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }
    
    // MARK: - Check-ins Section
    
    private func checkInsSection(pact: Pact) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-ins")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.1)
            
            ForEach(pact.checkIns.reversed()) { checkIn in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(checkIn.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                        
                        Spacer()
                        
                        Text("\(checkIn.progress)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.indigo)
                    }
                    
                    if let note = checkIn.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    ProgressBar(progress: Double(checkIn.progress), height: 3, color: AppColors.indigo)
                }
                .padding(14)
                .background(AppColors.surface)
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        VStack {
            Text("Pact not found.")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        PactDetailView(pactId: "test")
            .environmentObject(PactStore())
    }
}
