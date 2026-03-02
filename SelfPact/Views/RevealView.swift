import SwiftUI

enum RevealPhase {
    case intro
    case goal
    case question
    case reflection
    case complete
}

struct RevealView: View {
    let pactId: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var pactStore: PactStore
    
    @State private var phase: RevealPhase = .intro
    @State private var selectedOutcome: PactOutcome?
    @State private var reflection: String = ""
    
    // Animation states
    @State private var introOpacity: Double = 0
    @State private var introOffset: CGFloat = 20
    @State private var goalOpacity: Double = 0
    @State private var goalOffset: CGFloat = 16
    @State private var questionOpacity: Double = 0
    @State private var completeOpacity: Double = 0
    @State private var completeScale: CGFloat = 0.9
    @State private var glowOpacity: Double = 0.15
    @State private var glowScale: CGFloat = 0.85
    
    private var pact: Pact? {
        pactStore.getPact(id: pactId)
    }
    
    private var sealDate: String {
        guard let pact = pact else { return "" }
        let date = pact.sealTimestamp ?? pact.createdAt
        return date.formatted(.dateTime.month(.wide).day().year())
    }
    
    var body: some View {
        ZStack {
            AppColors.revealBackground.ignoresSafeArea()
            
            if pact == nil {
                notFoundView
            } else {
                switch phase {
                case .intro:
                    introPhase
                case .goal, .question:
                    goalPhase
                case .reflection:
                    reflectionPhase
                case .complete:
                    completePhase
                }
            }
        }
        .onAppear {
            startIntroAnimation()
        }
    }
    
    // MARK: - Intro Phase
    
    private var introPhase: some View {
        VStack(spacing: 10) {
            Text("On \(sealDate),")
                .font(.system(size: 17))
                .italic()
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.3)
            
            Text("you made this promise.")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.3)
                .multilineTextAlignment(.center)
        }
        .opacity(introOpacity)
        .offset(y: introOffset)
        .padding(.horizontal, 32)
    }
    
    // MARK: - Goal Phase
    
    private var goalPhase: some View {
        VStack(spacing: 0) {
            // Goal card
            VStack(spacing: 0) {
                if let pact = pact {
                    Text(pact.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    if let why = pact.why, !why.isEmpty {
                        Text(why)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 12)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .opacity(goalOpacity)
            .offset(y: goalOffset)
            
            // Question
            if phase == .question {
                questionSection
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var questionSection: some View {
        VStack(spacing: 20) {
            Text("Did you achieve it?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.2)
            
            VStack(spacing: 10) {
                // Yes button
                Button {
                    handleOutcome(.yes)
                } label: {
                    Text("Yes")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.gold)
                        .cornerRadius(14)
                        .shadow(color: AppColors.gold.opacity(0.25), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                // Secondary buttons
                HStack(spacing: 10) {
                    Button {
                        handleOutcome(.partially)
                    } label: {
                        Text("Partially")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.surface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        handleOutcome(.notYet)
                    } label: {
                        Text("Not Yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.surface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 32)
        .opacity(questionOpacity)
    }
    
    // MARK: - Reflection Phase
    
    private var reflectionPhase: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("What changed?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.4)
                    .padding(.bottom, 8)
                
                Text("Reflect on what happened and what you learned.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .padding(.bottom, 24)
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $reflection)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 140)
                    
                    if reflection.isEmpty {
                        Text("Write your reflection...")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .background(AppColors.surface)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .padding(.bottom, 20)
                
                Button {
                    handleReflectionSubmit()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.indigo)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding(28)
        }
    }
    
    // MARK: - Complete Phase
    
    private var completePhase: some View {
        GeometryReader { geometry in
            ZStack {
                // Glow circle (only for "yes" outcome)
                if selectedOutcome == .yes {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: geometry.size.width * 0.65, height: geometry.size.width * 0.65)
                        .opacity(glowOpacity)
                        .scaleEffect(glowScale)
                }
            
            VStack(spacing: 0) {
                Text(completeTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.3)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                
                Text(completeSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .padding(.horizontal, 52)
                        .padding(.vertical, 16)
                        .background(AppColors.gold)
                        .cornerRadius(14)
                        .shadow(color: AppColors.gold.opacity(0.25), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .opacity(completeOpacity)
            .scaleEffect(completeScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 32)
    }
    
    private var completeTitle: String {
        switch selectedOutcome {
        case .yes: return "You kept your promise."
        case .partially: return "Progress was made."
        case .notYet: return "The journey continues."
        case nil: return ""
        }
    }
    
    private var completeSubtitle: String {
        selectedOutcome == .yes
            ? "This pact has been honored."
            : "Your reflection has been recorded."
    }
    
    // MARK: - Not Found View
    
    private var notFoundView: some View {
        Text("Pact not found.")
            .font(.system(size: 16))
            .foregroundColor(AppColors.textSecondary)
    }
    
    // MARK: - Animations
    
    private func startIntroAnimation() {
        // Fade in intro
        withAnimation(.easeOut(duration: 1.2)) {
            introOpacity = 1
            introOffset = 0
        }
        
        // Transition to goal after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                introOpacity = 0
                introOffset = -10
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                phase = .goal
                startGoalAnimation()
            }
        }
    }
    
    private func startGoalAnimation() {
        withAnimation(.easeOut(duration: 0.9)) {
            goalOpacity = 1
            goalOffset = 0
        }
        
        // Show question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = .question
            withAnimation(.easeOut(duration: 0.7)) {
                questionOpacity = 1
            }
        }
    }
    
    private func startCompleteAnimation() {
        withAnimation(.easeOut(duration: 0.9)) {
            completeOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            completeScale = 1
        }
        
        if selectedOutcome == .yes {
            // Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Glow animation loop
            startGlowAnimation()
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            glowOpacity = 0.5
            glowScale = 1.1
        }
    }
    
    // MARK: - Actions
    
    private func handleOutcome(_ outcome: PactOutcome) {
        selectedOutcome = outcome
        
        // Light haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if outcome == .yes {
            pactStore.completePact(id: pactId, outcome: outcome)
            phase = .complete
            startCompleteAnimation()
        } else {
            phase = .reflection
        }
    }
    
    private func handleReflectionSubmit() {
        if let outcome = selectedOutcome {
            pactStore.completePact(
                id: pactId,
                outcome: outcome,
                reflection: reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reflection.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        phase = .complete
        startCompleteAnimation()
    }
}

#Preview {
    RevealView(pactId: "test")
        .environmentObject(PactStore())
}
