import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var showPurchase = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? AppColors.gold : AppColors.textMuted)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // TabView for horizontal swiping
                TabView(selection: $currentPage) {
                    OnboardingScreen1()
                        .tag(0)
                    
                    OnboardingScreen2()
                        .tag(1)
                    
                    OnboardingScreen3()
                        .tag(2)
                    
                    OnboardingScreen4(
                        onStartTapped: {
                            isPresented = false
                        },
                        onViewSealsOptions: {
                            showPurchase = true
                        }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Continue button (hidden on last page)
                if currentPage < 3 {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppColors.gold)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                    .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPurchase) {
            PurchaseView(onPurchaseComplete: {
                // Dismiss onboarding after successful purchase
                isPresented = false
            })
        }
    }
}

// MARK: - Screen 1: Philosophy
struct OnboardingScreen1: View {
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Headline
                Text("Make a promise to\nyour future self.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Subheadline
                VStack(spacing: 8) {
                    Text("Not a goal.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("A contract.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.gold)
                }
                
                // Supporting text
                Text("SelfPact helps you write commitments that\ncannot be edited once sealed.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 40)
            .opacity(opacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Screen 2: How It Works
struct OnboardingScreen2: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 28) {
                // Headline
                Text("Write it clearly.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)
                
                // Subheadline
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppColors.goldGlow)
                            .frame(width: 6, height: 6)
                        Text("Choose what you want to achieve.")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppColors.goldGlow)
                            .frame(width: 6, height: 6)
                        Text("Set a deadline.")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AppColors.goldGlow)
                            .frame(width: 6, height: 6)
                        Text("Be specific.")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 8)
                
                // Footer
                Text("Clarity creates commitment.")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.top, 24)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Screen 3: The Rule
struct OnboardingScreen3: View {
    @State private var showUnderline = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 28) {
                // Headline with animated underline
                VStack(spacing: 8) {
                    Text("Once sealed,")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.5)
                    
                    VStack(spacing: 4) {
                        Text("it cannot be changed.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.gold)
                            .tracking(-0.5)
                        
                        // Gold underline
                        Rectangle()
                            .fill(AppColors.gold)
                            .frame(width: showUnderline ? 260 : 0, height: 2)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: showUnderline)
                    }
                }
                
                // Subheadline
                VStack(spacing: 12) {
                    Text("No edits.")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No deleting.")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("No backtracking.")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 8)
                
                // Footer
                Text("Discipline begins with finality.")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.top, 28)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            showUnderline = true
        }
    }
}

// MARK: - Screen 4: Free Seal + Purchase Intro
struct OnboardingScreen4: View {
    let onStartTapped: () -> Void
    let onViewSealsOptions: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                // Headline
                Text("You get 1 seal free.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                
                // Subheadline
                Text("Use it wisely.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.gold)
                    .padding(.bottom, 8)
                
                // Supporting text
                Text("Seal a pact when you are ready to commit.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Divider
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                
                // Purchase info
                VStack(spacing: 8) {
                    Text("Need more seals later?")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("You can purchase additional seals anytime.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Primary button
                Button {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    onStartTapped()
                } label: {
                    Text("Start with 1 Free Seal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.gold)
                        .cornerRadius(14)
                        .shadow(color: AppColors.gold.opacity(0.25), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                // Secondary button
                Button {
                    onViewSealsOptions()
                } label: {
                    Text("View Seal Options")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
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
