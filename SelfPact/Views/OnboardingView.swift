import SwiftUI

private struct OnboardingGoalTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let exampleGoal: String
    let measurableTarget: String
    let nextAction: String
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var pactStore: PactStore

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
            } else {
                builderStep
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: createdPact?.id)
        .onAppear {
            applyTemplate(selectedTemplate)
        }
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
}

private enum OnboardingField: Hashable {
    case goal
    case target
    case action
}

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
