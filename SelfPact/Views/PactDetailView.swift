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
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
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
        .alert("Delete Goal", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                pactStore.deletePact(id: pactId)
                dismiss()
            }
        } message: {
            Text(pact?.isSealed == true
                 ? "This goal is locked. Deleting it will not restore your commitment. This action cannot be undone."
                 : "Are you sure you want to delete this draft goal?")
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
                            .foregroundColor(AppColors.accent)
                        
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
                        .foregroundColor(AppColors.accent)
                    
                    Text("Locked")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.accentGlow)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.accentLight.opacity(0.6), lineWidth: 1)
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
                    valueColor: pact.isReady ? AppColors.accent : AppColors.textPrimary
                )
            }
            
            if let sealTimestamp = pact.sealTimestamp {
                Divider()
                    .background(AppColors.border)
                    .padding(.horizontal, 12)
                
                // Locked on
                metaRow(
                    icon: "shield",
                    label: "Locked on",
                    value: sealTimestamp.formatted(.dateTime.month(.abbreviated).day().year())
                )
            }
        }
        .background(AppColors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
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
        VStack(spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Text("Timeline")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .tracking(0.3)
                
                Spacer()
                
                Text("\(Int(pact.timeProgress))")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(AppColors.accent)
                    .tracking(-1.2)
                +
                Text("%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.accentLight)
            }
            
            ProgressBar(
                progress: pact.timeProgress,
                height: 6,
                color: AppColors.accent,
                trackColor: AppColors.border
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundElevated)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
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
                    .foregroundColor(AppColors.accent)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.accent)
            }
            .padding(16)
            .background(AppColors.backgroundElevated)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }
    
    private var revealButton: some View {
        Button {
            showReveal = true
        } label: {
            Text("Review This Goal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.accentStrong)
                .cornerRadius(16)
                .shadow(color: AppColors.accent.opacity(0.16), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }
    
    private var sealButton: some View {
        NavigationLink(destination: PreviewPactView(pactId: pactId)) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                
                Text("Review & Lock")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(-0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppColors.accentStrong)
            .cornerRadius(16)
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
                            .foregroundColor(AppColors.accent)
                    }
                    
                    if let note = checkIn.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    ProgressBar(progress: Double(checkIn.progress), height: 3, color: AppColors.accent)
                }
                .padding(14)
                .background(AppColors.backgroundElevated)
                .cornerRadius(16)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        VStack {
            Text("Goal not found.")
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
