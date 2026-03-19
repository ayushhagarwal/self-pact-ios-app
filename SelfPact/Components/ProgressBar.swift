import SwiftUI

struct ProgressBar: View {
    let progress: Double
    var height: CGFloat = 4
    var color: Color = AppColors.accent
    var trackColor: Color = AppColors.border
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(trackColor)
                    .frame(height: height)
                
                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * (min(max(animatedProgress, 0), 100) / 100), height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(progress: 30)
        ProgressBar(progress: 60, color: AppColors.indigo)
        ProgressBar(progress: 100, height: 6, color: AppColors.success)
    }
    .padding()
    .background(AppColors.background)
}
