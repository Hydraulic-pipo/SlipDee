import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceModeRawValue = AppAppearanceMode.system.rawValue

    private var selectedMode: AppAppearanceMode {
        AppAppearanceMode(rawValue: appearanceModeRawValue) ?? .system
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Appearance")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Choose how SlipDee should look across the app.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    AppCard {
                        VStack(spacing: 0) {
                            ForEach(Array(AppAppearanceMode.allCases.enumerated()), id: \.element.id) { index, mode in
                                Button {
                                    appearanceModeRawValue = mode.rawValue
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: iconName(for: mode))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(AppColors.darkTeal)
                                            .frame(width: 34, height: 34)
                                            .background(AppColors.softTealBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                        Text(mode.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppColors.primaryText)

                                        Spacer()

                                        if selectedMode == mode {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(AppColors.primaryTeal)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                if index < AppAppearanceMode.allCases.count - 1 {
                                    Divider()
                                        .overlay(AppColors.border)
                                        .padding(.leading, 48)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func iconName(for mode: AppAppearanceMode) -> String {
        switch mode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
}
