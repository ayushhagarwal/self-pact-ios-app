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
    @State private var particles: [ParticleState] = []
    
    private let particleCount = 16
    
    struct ParticleState: Identifiable {
        let id = UUID()
        var x: CGFloat = 0
        var y: CGFloat = 0
        var opacity: Double = 0
        var scale: CGFloat = 0
        var size: CGFloat
    }
    
    var body: some View {
        if visible {
            ZStack {
                // Overlay
                Color.black.opacity(0.88)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                
                // Card container
                VStack(spacing: 0) {
                    ZStack {
                        // Particles
                        ForEach(particles) { particle in
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: particle.size, height: particle.size)
                                .offset(x: particle.x, y: particle.y)
                                .opacity(particle.opacity)
                                .scaleEffect(particle.scale)
                        }
                        
                        // Ring
                        Circle()
                            .stroke(AppColors.gold, lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                        
                        // Seal badge
                        ZStack {
                            Circle()
                                .fill(AppColors.goldGlow)
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.gold, lineWidth: 3)
                                )
                            
                            Circle()
                                .stroke(AppColors.goldDim, lineWidth: 1.5)
                                .frame(width: 60, height: 60)
                            
                            Text("S")
                                .font(.system(size: 30, weight: .bold))
                                .italic()
                                .foregroundColor(AppColors.gold)
                        }
                        .scaleEffect(sealScale)
                        .rotationEffect(.degrees(sealRotation))
                    }
                    .frame(height: 88)
                    
                    // Text
                    Text("Your pact is sealed.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.3)
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .padding(.top, 28)
                    
                    Text("This commitment is now immutable.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(lockOpacity)
                        .padding(.top, 6)
                }
                .padding(.vertical, 44)
                .padding(.horizontal, 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(AppColors.goldMuted, lineWidth: 1)
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
        // Initialize particles
        particles = (0..<particleCount).map { i in
            ParticleState(size: i % 3 == 0 ? 5 : 4)
        }
        
        // Phase 1: Fade in overlay and card
        withAnimation(.easeOut(duration: 0.5)) {
            overlayOpacity = 1
            cardOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cardScale = 1
        }
        
        // Phase 2: Seal animation (after 900ms delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
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
            
            // Particles
            for i in 0..<particleCount {
                let angle = (Double(i) / Double(particleCount)) * .pi * 2
                let distance = 70 + Double.random(in: 0...70)
                let targetX = CGFloat(cos(angle) * distance)
                let targetY = CGFloat(sin(angle) * distance - 20)
                
                withAnimation(.easeOut(duration: 0.25)) {
                    particles[i].opacity = 0.9
                }
                withAnimation(.easeOut(duration: 0.7)) {
                    particles[i].scale = CGFloat(0.4 + Double.random(in: 0...0.9))
                }
                withAnimation(.easeOut(duration: 1.4)) {
                    particles[i].x = targetX
                    particles[i].y = targetY
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
            
            // Fade out particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                for i in 0..<particleCount {
                    withAnimation(.easeOut(duration: 0.7)) {
                        particles[i].opacity = 0
                    }
                }
            }
            
            // Complete after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                onComplete()
            }
        }
    }
}

#Preview {
    SealAnimation(visible: true, onComplete: {})
        .background(AppColors.background)
}
