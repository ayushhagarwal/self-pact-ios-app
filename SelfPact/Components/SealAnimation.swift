import SwiftUI

struct SealAnimation: View {
    let visible: Bool
    let onComplete: () -> Void

    @State private var overlayOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.92
    @State private var cardOpacity: Double = 0
    @State private var markScale: CGFloat = 0.82
    @State private var ringTrim: CGFloat = 0
    @State private var lockOffset: CGFloat = 12
    @State private var checkTrim: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var actionOpacity: Double = 0

    var body: some View {
        if visible {
            ZStack {
                Color.black.opacity(0.28)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    LockConfirmationMark(
                        ringTrim: ringTrim,
                        checkTrim: checkTrim,
                        lockOffset: lockOffset
                    )
                    .frame(width: 142, height: 142)
                    .scaleEffect(markScale)

                    VStack(spacing: 8) {
                        Text("Goal locked")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .tracking(-0.6)
                            .multilineTextAlignment(.center)

                        Text("Your commitment is active. Today will keep the next small action front and center.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(textOpacity)

                    Button {
                        onComplete()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppColors.commitment)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .opacity(actionOpacity)
                    .accessibilityLabel("Continue")
                }
                .padding(.vertical, 34)
                .padding(.horizontal, 26)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(AppColors.surface)

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.commitmentGlow.opacity(0.7),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 30, x: 0, y: 18)
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .frame(maxWidth: 360)
                .padding(.horizontal, 24)
                .accessibilityElement(children: .contain)
            }
            .onAppear {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.22)) {
            overlayOpacity = 1
            cardOpacity = 1
        }

        withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
            cardScale = 1
            markScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.55)) {
                ringTrim = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                lockOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.54) {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)

            withAnimation(.easeInOut(duration: 0.34)) {
                checkTrim = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.74) {
            withAnimation(.easeOut(duration: 0.28)) {
                textOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
            withAnimation(.easeOut(duration: 0.28)) {
                actionOpacity = 1
            }
        }
    }
}

private struct LockConfirmationMark: View {
    let ringTrim: CGFloat
    let checkTrim: CGFloat
    let lockOffset: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.commitmentGlow.opacity(0.58))
                .frame(width: 138, height: 138)

            Circle()
                .stroke(AppColors.borderLight, lineWidth: 13)
                .frame(width: 118, height: 118)

            Circle()
                .trim(from: 0, to: ringTrim)
                .stroke(
                    AppColors.commitment,
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 118, height: 118)

            VStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(AppColors.commitment)
                    .offset(y: lockOffset)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppColors.surface)
                        .frame(width: 86, height: 70)
                        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 7)

                    CheckMarkShape()
                        .trim(from: 0, to: checkTrim)
                        .stroke(
                            AppColors.accentStrong,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 42, height: 34)
                }
                .offset(y: -7)
            }
        }
    }
}

private struct CheckMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY + rect.height * 0.88))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.96, y: rect.minY + rect.height * 0.12))
        return path
    }
}

#Preview {
    SealAnimation(visible: true, onComplete: {})
        .background(AppColors.background)
}
