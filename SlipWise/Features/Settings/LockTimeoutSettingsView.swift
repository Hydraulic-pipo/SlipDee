import SwiftUI

struct LockTimeoutSettingsView: View {
    @AppStorage(AppSettingsKey.lockTimeout) private var lockTimeoutRawValue = AppLockTimeout.immediate.rawValue

    private var selectedTimeout: AppLockTimeout {
        AppLockTimeout(rawValue: lockTimeoutRawValue) ?? .immediate
    }

    private let supportedTimeouts: [AppLockTimeout] = [
        .immediate,
        .oneMinute,
        .fiveMinutes,
        .fifteenMinutes
    ]

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Lock Timeout")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Choose how quickly SlipDee should lock again after it goes to the background.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    AppCard {
                        VStack(spacing: 0) {
                            ForEach(Array(supportedTimeouts.enumerated()), id: \.element.id) { index, timeout in
                                Button {
                                    lockTimeoutRawValue = timeout.rawValue
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(AppColors.darkTeal)
                                            .frame(width: 34, height: 34)
                                            .background(AppColors.softTealBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                        Text(timeout.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppColors.primaryText)

                                        Spacer()

                                        if selectedTimeout == timeout {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(AppColors.primaryTeal)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(.plain)

                                if index < supportedTimeouts.count - 1 {
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
        .navigationTitle("Lock Timeout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
