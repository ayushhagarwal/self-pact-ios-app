import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showPurchase = false
    @State private var backgroundDrift: CGFloat = 0
    @State private var ctaShimmerOffset: CGFloat = -220
    @State private var contentVisible: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFFFFF"),
                    Color(hex: "F5FAF7")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFFFFF").opacity(0.0),
                    Color(hex: "F5FAF7").opacity(0.45),
                    Color(hex: "FFFFFF").opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .offset(y: backgroundDrift)
            .onAppear {
                withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                    backgroundDrift = -24
                }
            }

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<2) { index in
                        Circle()
                            .fill(index == currentPage ? AppColors.accentStrong : AppColors.textMuted)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 32)

                TabView(selection: $currentPage) {
                    OnboardingScreen1()
                        .tag(0)

                    OnboardingScreen2(
                        onStartTapped: {
                            isPresented = false
                        },
                        onViewOptions: {
                            showPurchase = true
                        }
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                if currentPage == 0 {
                    Button {
                        withAnimation {
                            currentPage = 1
                        }
                    } label: {
                        Text("Lock This Goal")
                            .font(.app(16, .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .primaryButtonChrome(cornerRadius: 16)
                            .overlay(
                                GeometryReader { proxy in
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.20),
                                            Color.white.opacity(0.0)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(width: 46)
                                    .rotationEffect(.degrees(14))
                                    .offset(x: ctaShimmerOffset, y: 0)
                                    .blur(radius: 0.2)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 16)
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                    )
                                }
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .transition(.opacity)
                }
            }
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.3), value: contentVisible)
        }
        .sheet(isPresented: $showPurchase) {
            PurchaseView(onPurchaseComplete: {
                isPresented = false
            })
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).delay(5.8).repeatForever(autoreverses: false)) {
                ctaShimmerOffset = 420
            }
            withAnimation(.easeOut(duration: 0.3)) {
                contentVisible = true
            }
        }
    }
}

// MARK: - Screen 1: Core Value + Visual
struct OnboardingScreen1: View {
    @State private var cardScale: CGFloat = 0.96
    @State private var cardOpacity: Double = 0
    @State private var cardEntranceOffset: CGFloat = 18
    @State private var cardFloatOffset: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var progressFill: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)

            OnboardingPreviewCard(progress: progressFill)
                .scaleEffect(1.03 * cardScale)
                .opacity(cardOpacity)
                .offset(y: -40 + cardEntranceOffset + cardFloatOffset)
                .padding(.horizontal, 28)
                .padding(.bottom, 30)

            VStack(spacing: 12) {
                Text("Lock your goals.\nNo going back.")
                    .font(.app(32, .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.6)
                    .multilineTextAlignment(.center)

                Text("Once locked, it's final.")
                    .font(.app(16, .medium))
                    .foregroundColor(AppColors.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .opacity(textOpacity)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.30)) {
                cardScale = 1.0
                cardOpacity = 1
                cardEntranceOffset = 0
            }

            withAnimation(.easeOut(duration: 0.30).delay(0.05)) {
                progressFill = 0.25
            }

            withAnimation(.easeOut(duration: 0.30).delay(0.14)) {
                textOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                    progressFill = 0.30
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true)) {
                    cardFloatOffset = -5
                }
            }
        }
    }
}

private struct OnboardingPreviewCard: View {
    let progress: CGFloat
    @State private var badgeScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "7FB77E").opacity(0.07))
                .frame(width: 320, height: 320)
                .blur(radius: 56)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Run a Marathon")
                            .font(.app(22, .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .tracking(-0.25)

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(hex: "E5E7EB"))

                                Capsule()
                                    .fill(Color(hex: "7FB77E"))
                                    .frame(width: proxy.size.width * max(0, min(progress, 1)))
                            }
                        }
                        .frame(height: 6)

                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12, weight: .semibold))

                            Text("103 days left")
                                .font(.app(14, .medium))
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))

                        Text("Locked")
                            .font(.app(12, .semibold))
                    }
                    .foregroundColor(Color(hex: "2E7D32"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "E6F4EA"))
                    .clipShape(Capsule())
                    .scaleEffect(badgeScale)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
            .padding(18)
            .background(Color(hex: "FFFFFF"))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.borderLight, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 40, x: 0, y: 20)
            .rotationEffect(.degrees(-1.0))
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_600_000_000)
                withAnimation(.easeInOut(duration: 0.40)) {
                    badgeScale = 1.03
                }
                try? await Task.sleep(nanoseconds: 400_000_000)
                withAnimation(.easeInOut(duration: 0.40)) {
                    badgeScale = 1.0
                }
            }
        }
    }
}

// MARK: - Screen 2: Monetization + Clarity
struct OnboardingScreen2: View {
    let onStartTapped: () -> Void
    let onViewOptions: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("Start with 1 free commitment.")
                    .font(.app(34, .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.6)
                    .multilineTextAlignment(.center)

                Text("Use it when you're serious.\nYou can unlock more anytime.")
                    .font(.app(16, .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onStartTapped()
                } label: {
                    Text("Commit Now")
                        .font(.app(16, .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .primaryButtonChrome(cornerRadius: 16)
                }
                .buttonStyle(PressScaleButtonStyle())

                Button {
                    onViewOptions()
                } label: {
                    Text("See plans")
                        .font(.app(15, .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
        .environmentObject(PactStore())
        .environmentObject(StoreKitManager())
}
