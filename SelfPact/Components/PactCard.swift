import SwiftUI

struct PactCard: View {
    let pact: Pact
    var onPress: (() -> Void)?
    
    @State private var isPressed = false
    
    private var accentColor: Color {
        if pact.status == .completed {
            return AppColors.success
        } else if pact.status == .sealed {
            return AppColors.gold
        }
        return AppColors.textMuted
    }
    
    private var iconBackgroundColor: Color {
        if pact.status == .sealed {
            return AppColors.goldGlow
        } else if pact.status == .completed {
            return AppColors.successGlow
        }
        return AppColors.surfaceHighlight
    }
    
    var body: some View {
        cardContent
    }
    
    private var cardContent: some View {
        HStack(spacing: 0) {
            // Accent strip
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
            
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
                                } else if pact.status == .sealed {
                                    Image(systemName: "lock.fill")
                                } else {
                                    Image(systemName: "doc.text")
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundColor(accentColor)
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
                            color: pact.isOverdue ? AppColors.goldLight : AppColors.gold,
                            trackColor: AppColors.surfaceHighlight
                        )
                        
                        HStack(spacing: 5) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textTertiary)
                            
                            Text(pact.isOverdue ? "Ready to reveal" : "\(pact.daysRemaining)d remaining")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColors.textTertiary)
                        }
                    } else if pact.status == .draft {
                        // Draft badge
                        HStack {
                            Text("Draft")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.surfaceHighlight)
                                .cornerRadius(6)
                            
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
                                .foregroundColor(outcome == .yes ? AppColors.success : AppColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(outcome == .yes ? AppColors.successGlow : AppColors.surfaceHighlight)
                                .cornerRadius(6)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.leading, 38)
            }
            .padding(.vertical, 16)
            .padding(.leading, 14)
            .padding(.trailing, 16)
        }
        .background(AppColors.surface)
        .cornerRadius(16)
    }
    
    private func outcomeText(_ outcome: PactOutcome) -> String {
        switch outcome {
        case .yes: return "Achieved"
        case .partially: return "Partial"
        case .notYet: return "Reflected"
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
