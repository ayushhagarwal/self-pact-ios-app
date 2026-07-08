import SwiftUI

private struct OnboardingGoalTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let exampleGoal: String
    let measurableTarget: String
    let nextAction: String
}

private struct OnboardingIntroSlide: Identifiable {
    let id: String
    let title: String
    let caption: String
    let accent: Color
    let glow: Color
    let visual: OnboardingIntroVisual
}

private enum OnboardingIntroVisual {
    case create
    case track
    case lock
}

private enum OnboardingBuilderStep: Equatable {
    case goal
    case rhythm
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var pactStore: PactStore

    @State private var showBuilder = false
    @State private var builderPhase: OnboardingBuilderStep = .goal
    @State private var introAnimationActive = false
    @State private var selectedTemplate = onboardingTemplates[0]
    @State private var hasChosenTemplate = false
    @State private var goalTitle = ""
    @State private var target = ""
    @State private var nextAction = ""
    @State private var cadence: GoalCadence = .daily
    @State private var targetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date().addingTimeInterval(30 * 86_400)
    @State private var customWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var createdPact: Pact?
    @State private var isRequestingReminders = false
    @State private var creationError: String?
    @FocusState private var focusedField: OnboardingField?

    private var canCreateGoal: Bool {
        !goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var minimumTargetDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            if let createdPact {
                reminderStep(for: createdPact)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if showBuilder {
                builderStep
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                introStep
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: createdPact?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: showBuilder)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: hasChosenTemplate)
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: builderPhase)
        .onAppear {
            introAnimationActive = true
        }
    }

    private var introStep: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                OnboardingIntroCard(
                    slide: onboardingIntroSlide,
                    isActive: introAnimationActive
                )

                VStack(spacing: 8) {
                    Text(onboardingIntroSlide.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.7)
                        .multilineTextAlignment(.center)

                    Text(onboardingIntroSlide.caption)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 6)
            }

            Spacer(minLength: 16)

            Button {
                showBuilder = true
            } label: {
                Text("Make My First Pact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.accentStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(KineticPrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 34)
    }

    private var builderStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                builderHeader

                if builderPhase == .goal {
                    templatePicker

                    if hasChosenTemplate {
                        goalQuestion
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        continueButton
                    }
                } else {
                    cadencePicker
                    reviewDatePicker
                    pactSummaryCard
                    createButton
                    backButton
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }

    private var builderHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(builderPhase == .goal ? "Choose one goal" : "Set your rhythm")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.7)

            Text(builderPhase == .goal
                 ? "Pick a starting point, then shape it into one goal that feels like yours."
                 : "Decide when to check in and when you want to pause and review what changed.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(5)

            Text(builderPhase == .goal ? "1 of 2" : "2 of 2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.accentGlow)
                .clipShape(Capsule())
        }
    }

    private var goalQuestion: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR GOAL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .tracking(0.8)

                Text("This is the one promise you’re making.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }

            labeledGoalField(
                title: "Goal",
                hint: "What do you want to change?",
                placeholder: "e.g., Move my body consistently",
                text: $goalTitle,
                focus: .goal
            )

            labeledGoalField(
                title: "What counts as progress",
                hint: "A checkpoint for the same goal—not another goal.",
                placeholder: "e.g., Move for 20 minutes on check-in days",
                text: $target,
                focus: .target
            )

            labeledGoalField(
                title: "Next small action",
                hint: "The first step you can take today.",
                placeholder: "e.g., Walk for 20 minutes today",
                text: $nextAction,
                focus: .action
            )
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func labeledGoalField(
        title: String,
        hint: String,
        placeholder: String,
        text: Binding<String>,
        focus: OnboardingField
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(hint)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)

            TextField(placeholder, text: text, axis: .vertical)
                .textFieldStyle(PactTextFieldStyle())
                .focused($focusedField, equals: focus)
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick a starting point")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(onboardingTemplates) { template in
                    Button {
                        selectedTemplate = template
                        hasChosenTemplate = true
                        applyTemplate(template)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .background(hasChosenTemplate && template == selectedTemplate ? AppColors.accentGlowStrong : AppColors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 9))

                            Text(template.title)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer(minLength: 0)
                        }
                        .foregroundColor(hasChosenTemplate && template == selectedTemplate ? AppColors.accentStrong : AppColors.textSecondary)
                        .padding(12)
                        .background(hasChosenTemplate && template == selectedTemplate ? AppColors.accentGlow : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(hasChosenTemplate && template == selectedTemplate ? AppColors.accentLight : AppColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cadencePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How often do you want to check in?")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 8) {
                cadenceButton(.daily, title: "Daily")
                cadenceButton(.weekdays, title: "Weekdays")
                cadenceButton(.custom, title: "Custom")
            }

            if cadence == .custom {
                HStack(spacing: 7) {
                    ForEach(weekdayOptions, id: \.value) { weekday in
                        Button {
                            toggleWeekday(weekday.value)
                        } label: {
                            Text(weekday.label)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(customWeekdays.contains(weekday.value) ? .white : AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(customWeekdays.contains(weekday.value) ? AppColors.accentStrong : AppColors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func cadenceButton(_ value: GoalCadence, title: String) -> some View {
        Button {
            cadence = value
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(cadence == value ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(cadence == value ? AppColors.accentStrong : AppColors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var reviewDatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When do you want to review it?")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            DatePicker(
                "Review date",
                selection: $targetDate,
                in: minimumTargetDate...,
                displayedComponents: .date
            )
            .font(.system(size: 15, weight: .semibold))
            .tint(AppColors.accent)
            .padding(14)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.border, lineWidth: 1)
            )

            Text("Choose a date that gives this goal enough time to matter. There’s no required duration.")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
        }
    }

    private var pactSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your pact", systemImage: "lock.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.commitment)

            Text(goalTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Keep this promise unchanged until \(targetDate.formatted(.dateTime.month(.wide).day().year())). At the end, reflect honestly—success isn’t required.")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)

            if let creationError {
                Text(creationError)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.error)
            }
        }
        .padding(18)
        .background(AppColors.commitmentGlow.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var continueButton: some View {
        Button {
            focusedField = nil
            builderPhase = .rhythm
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(canCreateGoal ? AppColors.accentStrong : AppColors.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(KineticPrimaryButtonStyle())
        .disabled(!canCreateGoal)
    }

    private var createButton: some View {
        Button {
            createAndLockPact()
        } label: {
            Text("Make This Pact")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(canCreateGoal ? AppColors.accentStrong : AppColors.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(KineticPrimaryButtonStyle())
        .disabled(!canCreateGoal)
        .padding(.top, 4)
    }

    private var backButton: some View {
        Button {
            builderPhase = .goal
        } label: {
            Text("Back to Goal")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func reminderStep(for pact: Pact) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(AppColors.commitment)
                .frame(width: 84, height: 84)
                .background(AppColors.commitmentGlow)
                .clipShape(Circle())

            VStack(spacing: 10) {
                Text("You made a promise")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)

                Text(pact.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.commitment)
                    .multilineTextAlignment(.center)

                Text("Keep this promise unchanged until \(pact.targetDate.formatted(.dateTime.month(.wide).day().year())). At the end, reflect honestly—success isn’t required.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            VStack(spacing: 12) {
                Text("A gentle reminder can help you return to it.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)

                Button {
                    Task {
                        isRequestingReminders = true
                        await ReminderManager.requestPermissionAndSchedule(for: pact)
                        isRequestingReminders = false
                        isPresented = false
                    }
                } label: {
                    HStack {
                        if isRequestingReminders {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("Enable Reminders")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.accentStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(KineticPrimaryButtonStyle())
                .disabled(isRequestingReminders)

                Button {
                    isPresented = false
                } label: {
                    Text("Not Now")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(32)
    }

    private func applyTemplate(_ template: OnboardingGoalTemplate) {
        goalTitle = template.exampleGoal
        target = template.measurableTarget
        nextAction = template.nextAction
    }

    private func toggleWeekday(_ weekday: Int) {
        if customWeekdays.contains(weekday), customWeekdays.count > 1 {
            customWeekdays.remove(weekday)
        } else {
            customWeekdays.insert(weekday)
        }
    }

    private func createAndLockPact() {
        focusedField = nil
        creationError = nil

        let pact = pactStore.createPact(
            title: goalTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            why: nil,
            measurableTarget: target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : target.trimmingCharacters(in: .whitespacesAndNewlines),
            nextAction: nextAction,
            cadence: cadence,
            reminderWeekdays: cadence == .custom ? Array(customWeekdays) : nil,
            targetDate: targetDate
        )

        guard pactStore.sealPact(id: pact.id), let lockedPact = pactStore.getPact(id: pact.id) else {
            pactStore.deletePact(id: pact.id)
            creationError = "Your pact could not be locked. Please try again."
            return
        }

        createdPact = lockedPact
    }

}

private struct OnboardingIntroCard: View {
    let slide: OnboardingIntroSlide
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "082F25"),
                            Color(hex: "0E4935"),
                            Color(hex: "143B31")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.accentLight.opacity(0.34),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 250
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 250, height: 250)
                .scaleEffect(isActive ? 1 : 0.72)

            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 310, height: 310)
                .scaleEffect(isActive ? 1 : 0.78)

            introVisual
        }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: AppColors.commitment.opacity(0.24), radius: 28, x: 0, y: 18)
    }

    @ViewBuilder
    private var introVisual: some View {
        switch slide.visual {
        case .create:
            createVisual
        case .track:
            trackVisual
        case .lock:
            lockVisual
        }
    }

    private var createVisual: some View {
        ZStack {
            KineticOrbitBadge(icon: "target", label: "Choose", tint: AppColors.accentLight, isActive: isActive)
                .offset(x: -103, y: -82)
                .rotationEffect(.degrees(isActive ? -4 : -14))

            KineticOrbitBadge(icon: "checkmark", label: "Show up", tint: AppColors.accentLight, isActive: isActive)
                .offset(x: -92, y: 92)
                .rotationEffect(.degrees(isActive ? 5 : 14))

            KineticOrbitBadge(icon: "calendar", label: "Reflect", tint: AppColors.goldLight, isActive: isActive)
                .offset(x: 105, y: 66)
                .rotationEffect(.degrees(isActive ? -5 : 10))

            Image("AppIconHero")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 148)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.34), radius: 24, x: 0, y: 16)
                .scaleEffect(isActive ? 1 : 0.72)
                .opacity(isActive ? 1 : 0)
                .phaseAnimator(reduceMotion ? [false] : [false, true]) { content, phase in
                    content
                        .offset(y: phase ? -5 : 5)
                        .rotation3DEffect(
                            .degrees(phase ? 2.4 : -2.4),
                            axis: (x: 1, y: -1, z: 0)
                        )
                } animation: { _ in
                    .easeInOut(duration: 2.6)
                }

            Text("GOALLOCK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.68))
                .tracking(2.2)
                .offset(y: 139)
                .opacity(isActive ? 1 : 0)
        }
        .padding(18)
        .animation(.spring(response: 0.72, dampingFraction: 0.78), value: isActive)
    }

    private var trackVisual: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                OnboardingCheckInPill(title: "Did it", icon: "checkmark", tint: AppColors.success, isSelected: isActive)
                OnboardingCheckInPill(title: "Progress", icon: "circle.lefthalf.filled", tint: AppColors.warning, isSelected: false)
                OnboardingCheckInPill(title: "Not today", icon: "xmark", tint: AppColors.error, isSelected: false)
            }

            HStack(spacing: 10) {
                OnboardingStatTile(value: "4d", label: "Streak")
                OnboardingStatTile(value: "21d", label: "Left")
                OnboardingStatTile(value: "Today", label: "Last")
            }
        }
        .padding(24)
        .scaleEffect(isActive ? 1 : 0.96)
        .opacity(isActive ? 1 : 0.35)
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: isActive)
    }

    private var lockVisual: some View {
        ZStack {
            Circle()
                .stroke(AppColors.commitmentGlow, lineWidth: 15)
                .frame(width: 152, height: 152)

            Circle()
                .trim(from: 0, to: isActive ? 0.82 : 0.18)
                .stroke(
                    AppColors.commitment,
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 152, height: 152)

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppColors.commitment)

                Text("3 locks included")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.commitment)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.surface)
                    .clipShape(Capsule())
            }
            .scaleEffect(isActive ? 1 : 0.9)
        }
        .animation(.easeInOut(duration: 0.52), value: isActive)
    }
}

private struct KineticOrbitBadge: View {
    let icon: String
    let label: String
    let tint: Color
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tint)

            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.11))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 6)
        .scaleEffect(isActive ? 1 : 0.7)
        .opacity(isActive ? 1 : 0)
        .phaseAnimator(reduceMotion ? [false] : [false, true]) { content, phase in
            content.offset(y: phase ? -3 : 3)
        } animation: { _ in
            .easeInOut(duration: 2.2)
        }
        .animation(.spring(response: 0.7, dampingFraction: 0.72), value: isActive)
    }
}

private struct KineticPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .shadow(
                color: AppColors.accentStrong.opacity(configuration.isPressed ? 0.08 : 0.2),
                radius: configuration.isPressed ? 4 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 7
            )
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct OnboardingMiniGoalCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .background(AppColors.accentGlow)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

private struct OnboardingCheckInPill: View {
    let title: String
    let icon: String
    let tint: Color
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(isSelected ? .white : tint)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(isSelected ? tint : AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? tint.opacity(0.2) : AppColors.border, lineWidth: 1)
        )
    }
}

private struct OnboardingStatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

private enum OnboardingField: Hashable {
    case goal
    case target
    case action
}

private let onboardingIntroSlide = OnboardingIntroSlide(
    id: "welcome",
    title: "One promise. One small action.",
    caption: "Choose something meaningful, check in honestly, and learn what helps you keep going.",
    accent: AppColors.accent,
    glow: AppColors.accentGlow,
    visual: .create
)

private let onboardingTemplates: [OnboardingGoalTemplate] = [
    OnboardingGoalTemplate(
        id: "fitness",
        title: "Fitness",
        icon: "figure.run",
        exampleGoal: "Move my body consistently",
        measurableTarget: "Complete 20 minutes of movement on check-in days.",
        nextAction: "Walk for 20 minutes today."
    ),
    OnboardingGoalTemplate(
        id: "study",
        title: "Study",
        icon: "book.closed",
        exampleGoal: "Study without falling behind",
        measurableTarget: "Complete one focused study block on check-in days.",
        nextAction: "Do one 25-minute study session."
    ),
    OnboardingGoalTemplate(
        id: "money",
        title: "Money",
        icon: "banknote",
        exampleGoal: "Spend more intentionally",
        measurableTarget: "Review spending and avoid one unnecessary purchase.",
        nextAction: "Check today's spending once."
    ),
    OnboardingGoalTemplate(
        id: "focus",
        title: "Focus",
        icon: "timer",
        exampleGoal: "Protect deep work time",
        measurableTarget: "Complete one distraction-free focus block.",
        nextAction: "Start one 30-minute focus block."
    ),
    OnboardingGoalTemplate(
        id: "personal",
        title: "Personal",
        icon: "person.crop.circle",
        exampleGoal: "Show up for myself",
        measurableTarget: "Do one small action that supports this change.",
        nextAction: "Choose the smallest useful step."
    )
]

private let weekdayOptions: [(label: String, value: Int)] = [
    ("S", 1),
    ("M", 2),
    ("T", 3),
    ("W", 4),
    ("T", 5),
    ("F", 6),
    ("S", 7)
]

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(PactStore())
}
