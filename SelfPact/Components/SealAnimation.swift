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
    @State private var spotlightScale: CGFloat = 0.3
    @State private var spotlightOpacity: Double = 0
    @State private var shimmerParticles: [ParticleState] = []
    
    private let particleCount = 24
    
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
                // Overlay with blur
                Color.black.opacity(0.92)
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                
                // Radial spotlight
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppColors.gold.opacity(0.15),
                        AppColors.gold.opacity(0.05),
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
                        // Explosion particles
                        ForEach(particles) { particle in
                            Circle()
                                .fill(AppColors.gold)
                                .frame(width: particle.size, height: particle.size)
                                .offset(x: particle.x, y: particle.y)
                                .opacity(particle.opacity)
                                .scaleEffect(particle.scale)
                        }
                        
                        // Shimmer particles (floating gold dust)
                        ForEach(shimmerParticles) { particle in
                            Circle()
                                .fill(AppColors.goldLight)
                                .frame(width: particle.size, height: particle.size)
                                .offset(x: particle.x, y: particle.y)
                                .opacity(particle.opacity)
                                .scaleEffect(particle.scale)
                                .blur(radius: 0.5)
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
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .tracking(-0.8)
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .padding(.top, 32)
                    
                    Text("This commitment is now immutable.")
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
        // Initialize explosion particles
        particles = (0..<particleCount).map { i in
            ParticleState(size: i % 3 == 0 ? 5 : 4)
        }
        
        // Initialize shimmer particles (floating gold dust)
        shimmerParticles = (0..<12).map { i in
            let size: CGFloat = i % 2 == 0 ? 3 : 2
            return ParticleState(size: size)
        }
        
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
            
            // Explosion particles
            for i in 0..<particleCount {
                let angle = (Double(i) / Double(particleCount)) * .pi * 2
                let distance = 70 + Double.random(in: 0...80)
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
            
            // Shimmer particles (floating gold dust)
            for i in 0..<shimmerParticles.count {
                let delay = Double.random(in: 0.2...0.8)
                let targetX = CGFloat.random(in: -60...60)
                let targetY = CGFloat.random(in: -40...40)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 2.0)) {
                        shimmerParticles[i].opacity = Double.random(in: 0.3...0.6)
                        shimmerParticles[i].scale = CGFloat.random(in: 0.5...1.0)
                        shimmerParticles[i].x = targetX
                        shimmerParticles[i].y = targetY
                    }
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
