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

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var pactStore: PactStore

    @State private var showBuilder = false
    @State private var introIndex = 0
    @State private var introAnimationActive = false
    @State private var selectedTemplate = onboardingTemplates[0]
    @State private var goalTitle = ""
    @State private var target = ""
    @State private var nextAction = ""
    @State private var cadence: GoalCadence = .daily
    @State private var customWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var reviewDate = Date().addingTimeInterval(86400 * 30)
    @State private var createdPact: Pact?
    @State private var isRequestingReminders = false
    @FocusState private var focusedField: OnboardingField?

    private var canCreateGoal: Bool {
        !goalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        .onAppear {
            applyTemplate(selectedTemplate)
            introAnimationActive = true
        }
    }

    private var currentIntroSlide: OnboardingIntroSlide {
        onboardingIntroSlides[introIndex]
    }

    private var introStep: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                OnboardingIntroCard(
                    slide: currentIntroSlide,
                    isActive: introAnimationActive
                )
                .id(currentIntroSlide.id)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))

                VStack(spacing: 8) {
                    Text(currentIntroSlide.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.7)
                        .multilineTextAlignment(.center)

                    Text(currentIntroSlide.caption)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 6)
            }

            Spacer(minLength: 16)

            VStack(spacing: 18) {
                introProgress

                Button {
                    advanceIntro()
                } label: {
                    Text(introIndex == onboardingIntroSlides.count - 1 ? "Build My First Goal" : "Next")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(AppColors.accentStrong)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 34)
    }

    private var introProgress: some View {
        HStack(spacing: 7) {
            ForEach(onboardingIntroSlides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == introIndex ? AppColors.accentStrong : AppColors.border)
                    .frame(width: index == introIndex ? 24 : 7, height: 7)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: introIndex)
            }
        }
        .accessibilityHidden(true)
    }

    private var builderStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                goalQuestion
                templatePicker
                cadencePicker
                reviewDatePicker
                createButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start with today")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .tracking(-0.7)

            Text("Create one trial goal. You can track it for free and lock it later if you want the extra commitment.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(5)
        }
    }

    private var goalQuestion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you trying to change?")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            TextField("e.g., Run three times this week", text: $goalTitle, axis: .vertical)
                .textFieldStyle(PactTextFieldStyle())
                .focused($focusedField, equals: .goal)

            TextField("What would count as progress?", text: $target, axis: .vertical)
                .textFieldStyle(PactTextFieldStyle())
                .focused($focusedField, equals: .target)

            TextField("Small action for today", text: $nextAction, axis: .vertical)
                .textFieldStyle(PactTextFieldStyle())
                .focused($focusedField, equals: .action)
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
                        applyTemplate(template)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: template.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .background(template == selectedTemplate ? AppColors.accentGlowStrong : AppColors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 9))

                            Text(template.title)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer(minLength: 0)
                        }
                        .foregroundColor(template == selectedTemplate ? AppColors.accentStrong : AppColors.textSecondary)
                        .padding(12)
                        .background(template == selectedTemplate ? AppColors.accentGlow : AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(template == selectedTemplate ? AppColors.accentLight : AppColors.border, lineWidth: 1)
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
                                .frame(height: 34)
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
            Text("Choose a review date")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            DatePicker(
                "Review date",
                selection: $reviewDate,
                in: Date().addingTimeInterval(86400)...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(AppColors.accentStrong)
            .padding(14)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var createButton: some View {
        Button {
            createTrialGoal()
        } label: {
            Text("Create Trial Goal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(canCreateGoal ? AppColors.accentStrong : AppColors.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!canCreateGoal)
        .padding(.top, 4)
    }

    private func reminderStep(for pact: Pact) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 84, height: 84)
                .background(AppColors.accentGlow)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 10) {
                Text("Your trial goal is ready")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)

                Text("A gentle reminder can bring you back for the check-in you just set up.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            VStack(spacing: 12) {
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
                .buttonStyle(.plain)
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

    private func createTrialGoal() {
        focusedField = nil

        let pact = pactStore.createPact(
            title: goalTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            why: nil,
            measurableTarget: target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : target.trimmingCharacters(in: .whitespacesAndNewlines),
            nextAction: nextAction,
            cadence: cadence,
            reminderWeekdays: cadence == .custom ? Array(customWeekdays) : nil,
            targetDate: reviewDate
        )

        createdPact = pact
    }

    private func advanceIntro() {
        if introIndex < onboardingIntroSlides.count - 1 {
            introAnimationActive = false
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                introIndex += 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                introAnimationActive = true
            }
        } else {
            showBuilder = true
        }
    }
}

private struct OnboardingIntroCard: View {
    let slide: OnboardingIntroSlide
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.surface)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            slide.glow.opacity(0.85),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            introVisual
        }
        .frame(height: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 22, x: 0, y: 12)
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
        VStack(spacing: 14) {
            OnboardingMiniGoalCard(
                icon: "target",
                title: "Move consistently",
                subtitle: "Walk 20 minutes today",
                tint: slide.accent
            )
            .offset(y: isActive ? 0 : 16)
            .opacity(isActive ? 1 : 0.2)

            HStack(spacing: 10) {
                ForEach(["Fitness", "Study", "Focus"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(slide.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.surface)
                        .clipShape(Capsule())
                }
            }
            .offset(y: isActive ? 0 : 12)
            .opacity(isActive ? 1 : 0)
        }
        .padding(24)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: isActive)
    }

    private var trackVisual: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                OnboardingCheckInPill(title: "Did it", icon: "checkmark", tint: AppColors.success, isSelected: isActive)
                OnboardingCheckInPill(title: "Partial", icon: "circle.lefthalf.filled", tint: AppColors.warning, isSelected: false)
                OnboardingCheckInPill(title: "Missed", icon: "xmark", tint: AppColors.error, isSelected: false)
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

                Text("First lock free")
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

private let onboardingIntroSlides: [OnboardingIntroSlide] = [
    OnboardingIntroSlide(
        id: "create",
        title: "Create a goal",
        caption: "Pick one change and the next action.",
        accent: AppColors.accent,
        glow: AppColors.accentGlow,
        visual: .create
    ),
    OnboardingIntroSlide(
        id: "track",
        title: "Track it daily",
        caption: "Check in without journaling.",
        accent: AppColors.accent,
        glow: AppColors.accentGlow,
        visual: .track
    ),
    OnboardingIntroSlide(
        id: "lock",
        title: "Lock it later",
        caption: "Your first lock is free. More locks use credits.",
        accent: AppColors.commitment,
        glow: AppColors.commitmentGlow,
        visual: .lock
    )
]

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
