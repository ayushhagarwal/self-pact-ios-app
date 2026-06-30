import SwiftUI

struct PactCard: View {
    let pact: Pact
    var onPress: (() -> Void)?
    
    @State private var isPressed = false
    
    private var accentColor: Color {
        if pact.status == .sealed {
            return pact.isOverdue ? AppColors.review : AppColors.commitment
        } else if pact.status == .completed {
            return AppColors.success
        } else if pact.status == .broken {
            return AppColors.error
        }
        return AppColors.border
    }
    
    private var iconBackgroundColor: Color {
        if pact.status == .sealed {
            return pact.isOverdue ? AppColors.reviewGlow : AppColors.commitmentGlow
        } else if pact.status == .completed {
            return AppColors.successGlow
        } else if pact.status == .broken {
            return AppColors.errorGlow
        }
        return AppColors.backgroundElevated
    }

    private var iconColor: Color {
        if pact.status == .sealed {
            return pact.isOverdue ? AppColors.review : AppColors.commitment
        } else if pact.status == .completed {
            return AppColors.success
        } else if pact.status == .broken {
            return AppColors.error
        }
        return AppColors.textSecondary
    }
    
    var body: some View {
        cardContent
    }
    
    private var cardContent: some View {
        HStack(spacing: 0) {
            // Accent strip
            Rectangle()
                .fill(accentColor)
                .frame(width: 2)
            
            // Card content
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(iconBackgroundColor)
                                .frame(width: 28, height: 28)
                            
                            Group {
                                if pact.status == .completed {
                                    Image(systemName: "checkmark.circle.fill")
                                } else if pact.status == .broken {
                                    Image(systemName: "lock.slash.fill")
                                } else if pact.status == .sealed {
                                    Image(systemName: "lock.fill")
                                } else {
                                    Image(systemName: "doc.text")
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(iconColor)
                        }
                        
                        Text(pact.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                            .tracking(-0.2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.bottom, 4)
                
                // Why text
                if let why = pact.why, !why.isEmpty {
                    Text(why)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(4)
                        .padding(.top, 4)
                        .padding(.leading, 38)
                }
                
                // Footer
                VStack(alignment: .leading, spacing: 6) {
                    if pact.status == .sealed && pact.status != .completed {
                        // Progress section
                        ProgressBar(
                            progress: pact.timeProgress,
                            height: 3,
                            color: pact.isOverdue ? AppColors.review : AppColors.commitment,
                            trackColor: AppColors.border
                        )
                        
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textTertiary)
                            
                            Text(pact.isOverdue ? "Ready to review" : "\(pact.daysRemaining)d remaining")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    } else if pact.status == .draft {
                        // Draft badge
                        HStack {
                            Text("Draft")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.backgroundElevated)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Text(pact.targetDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    } else if pact.status == .completed, let outcome = pact.outcome {
                        // Outcome badge
                        HStack {
                            Text(outcomeText(outcome))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(outcomeColor(outcome))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(outcomeBackground(outcome))
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                    } else if pact.status == .broken {
                        HStack {
                            Text("Pact broken")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.errorGlow)
                                .cornerRadius(8)

                            Spacer()

                            if let brokenAt = pact.brokenAt {
                                Text(brokenAt.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.leading, 38)
            }
            .padding(.vertical, 18)
            .padding(.leading, 14)
            .padding(.trailing, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border.opacity(0.8), lineWidth: 1)
        )
    }
    
    private func outcomeText(_ outcome: PactOutcome) -> String {
        switch outcome {
        case .yes: return "Achieved"
        case .partially: return "Partial"
        case .notYet: return "Reflected"
        }
    }

    private func outcomeColor(_ outcome: PactOutcome) -> Color {
        switch outcome {
        case .yes: return AppColors.success
        case .partially: return AppColors.warning
        case .notYet: return AppColors.textSecondary
        }
    }

    private func outcomeBackground(_ outcome: PactOutcome) -> Color {
        switch outcome {
        case .yes: return AppColors.successGlow
        case .partially: return AppColors.warningGlow
        case .notYet: return AppColors.backgroundElevated
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PactCard(
            pact: Pact(
                title: "Run a marathon",
                why: "Build discipline and physical fitness",
                targetDate: Date().addingTimeInterval(86400 * 30),
                isSealed: true,
                sealTimestamp: Date(),
                status: .sealed
            )
        )
        
        PactCard(
            pact: Pact(
                title: "Learn SwiftUI",
                targetDate: Date().addingTimeInterval(86400 * 60),
                status: .draft
            )
        )
        
        PactCard(
            pact: Pact(
                title: "Read 12 books",
                why: "Expand knowledge and perspective",
                targetDate: Date().addingTimeInterval(-86400),
                status: .completed,
                outcome: .yes
            )
        )
    }
    .padding()
    .background(AppColors.background)
}
