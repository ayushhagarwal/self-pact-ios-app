import SwiftUI

struct SealAnimation: View {
    let visible: Bool
    let onComplete: () -> Void
    
    @State private var overlayOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.82
    @State private var cardOpacity: Double = 0
    @State private var sealScale: CGFloat = 0
    @State private var sealRotation: Double = -25
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 12
    @State private var lockOpacity: Double = 0
    @State private var spotlightScale: CGFloat = 0.3
    @State private var spotlightOpacity: Double = 0
    
    var body: some View {
        if visible {
            ZStack {
                // Overlay with blur
                Color.black.opacity(0.12)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                
                // Radial spotlight
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppColors.accent.opacity(0.12),
                        AppColors.accent.opacity(0.04),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
                .scaleEffect(spotlightScale)
                .opacity(spotlightOpacity)
                
                // Card container
                VStack(spacing: 0) {
                    ZStack {
                        // Ring
                        Circle()
                            .stroke(AppColors.accent, lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                        
                        // Seal badge
                        ZStack {
                            Circle()
                                .fill(AppColors.accentGlow)
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.accent, lineWidth: 3)
                                )
                            
                            Circle()
                                .stroke(AppColors.accentDim, lineWidth: 1.5)
                                .frame(width: 60, height: 60)
                            
                            Text("S")
                                .font(.system(size: 30, weight: .bold))
                                .italic()
                                .foregroundColor(AppColors.accent)
                        }
                        .scaleEffect(sealScale)
                        .rotationEffect(.degrees(sealRotation))
                    }
                    .frame(height: 88)
                    
                    // Text
                    Text("Your goal is now locked.")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .padding(.top, 32)
                    
                    Text("This commitment is now locked.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(-0.1)
                        .multilineTextAlignment(.center)
                        .opacity(lockOpacity)
                        .padding(.top, 8)
                }
                .padding(.vertical, 44)
                .padding(.horizontal, 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .frame(maxWidth: 350)
                .padding(.horizontal, 32)
            }
            .onAppear {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Phase 1: Fade in overlay, spotlight, and card
        withAnimation(.easeOut(duration: 0.6)) {
            overlayOpacity = 1
            cardOpacity = 1
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            cardScale = 1
        }
        
        // Spotlight appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.2)) {
                spotlightOpacity = 1
                spotlightScale = 1.5
            }
        }
        
        // Phase 2: Seal animation (after 1000ms delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Stronger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Seal pop in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                sealScale = 1
            }
            withAnimation(.easeOut(duration: 0.7)) {
                sealRotation = 0
            }
            
            // Ring expansion
            withAnimation(.easeOut(duration: 0.6)) {
                ringOpacity = 0.6
                ringScale = 1.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    ringOpacity = 0
                }
            }
            
            // Text fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.6)) {
                    textOpacity = 1
                    textOffset = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        lockOpacity = 1
                    }
                }
            }
            
            // Complete after delay (extended for more dramatic timing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                onComplete()
            }
        }
    }
}

#Preview {
    SealAnimation(visible: true, onComplete: {})
        .background(AppColors.background)
}
