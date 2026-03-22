import SwiftUI

struct GlowModal<Content: View>: View {
    let title: String
    let subtitle: String?
    let onDismiss: () -> Void
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            ZStack {
                Circle()
                    .fill(AppColors.accentGlowStrong)
                    .frame(width: 220, height: 220)
                    .blur(radius: 18)
                    .offset(x: -90, y: -130)

                Circle()
                    .fill(AppColors.accent.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 22)
                    .offset(x: 110, y: 140)

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .tracking(-0.5)

                            if let subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineSpacing(4)
                            }
                        }

                        Spacer(minLength: 0)

                        Button {
                            onDismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.background)
                                    .frame(width: 34, height: 34)

                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    content
                }
                .padding(24)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppColors.accentLight.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
            }
            .padding(.horizontal, 20)
        }
        .environment(\.colorScheme, .light)
    }
}
