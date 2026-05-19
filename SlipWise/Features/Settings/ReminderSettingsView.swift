import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @AppStorage(AppSettingsKey.isDailyReminderEnabled) private var isDailyReminderEnabled = false
    @AppStorage(AppSettingsKey.dailyReminderHour) private var dailyReminderHour = 20
    @AppStorage(AppSettingsKey.dailyReminderMinute) private var dailyReminderMinute = 0

    @State private var helperMessage: String?
    @State private var showPermissionAlert = false
    @State private var isUpdatingReminder = false

    private let reminderService = NotificationReminderService()

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Reminders")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Daily Update Reminder")
                                .font(.headline)
                                .foregroundStyle(AppColors.primaryText)

                            Text("SlipDee can remind you each day to update your transactions.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)

                            Toggle("Daily Update Reminder", isOn: dailyReminderBinding)
                                .tint(AppColors.primaryTeal)
                                .font(.subheadline.weight(.semibold))

                            if isDailyReminderEnabled {
                                Divider()
                                    .overlay(AppColors.border)

                                DatePicker(
                                    "Reminder Time",
                                    selection: reminderTimeBinding,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .tint(AppColors.primaryTeal)
                            }
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Privacy")
                                .font(.headline)
                                .foregroundStyle(AppColors.primaryText)

                            Text("Reminders are scheduled locally on your device.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)

                            Text("SlipDee only uses a daily reminder and does not upload your data anywhere.")
                                .font(.footnote)
                                .foregroundStyle(AppColors.mutedText)
                        }
                    }

                    if let helperMessage {
                        AppCard {
                            Text(helperMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshHelperMessage()
            await reminderService.refreshDailyReminderIfNeeded(
                isEnabled: isDailyReminderEnabled,
                hour: dailyReminderHour,
                minute: dailyReminderMinute
            )
        }
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Notifications are disabled. Please enable notifications in iOS Settings to use reminders.")
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { makeReminderDate(hour: dailyReminderHour, minute: dailyReminderMinute) },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                dailyReminderHour = components.hour ?? 20
                dailyReminderMinute = components.minute ?? 0

                guard isDailyReminderEnabled, !isUpdatingReminder else { return }

                Task {
                    await reminderService.refreshDailyReminderIfNeeded(
                        isEnabled: true,
                        hour: dailyReminderHour,
                        minute: dailyReminderMinute
                    )
                    await refreshHelperMessage()
                }
            }
        )
    }

    private var dailyReminderBinding: Binding<Bool> {
        Binding(
            get: { isDailyReminderEnabled },
            set: { newValue in
                Task {
                    await updateReminderEnabled(newValue)
                }
            }
        )
    }

    @MainActor
    private func updateReminderEnabled(_ isEnabled: Bool) async {
        guard !isUpdatingReminder else { return }
        isUpdatingReminder = true
        defer { isUpdatingReminder = false }

        helperMessage = nil

        if !isEnabled {
            isDailyReminderEnabled = false
            reminderService.cancelDailyReminder()
            helperMessage = "Daily reminder turned off."
            return
        }

        let status = await reminderService.authorizationStatus()
        let isAuthorized: Bool

        switch status {
        case .authorized, .provisional:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await reminderService.requestAuthorization()
        case .denied:
            isAuthorized = false
        default:
            isAuthorized = false
        }

        guard isAuthorized else {
            isDailyReminderEnabled = false
            reminderService.cancelDailyReminder()
            helperMessage = "Notifications are disabled. Please enable notifications in iOS Settings to use reminders."
            showPermissionAlert = true
            return
        }

        isDailyReminderEnabled = true
        await reminderService.refreshDailyReminderIfNeeded(
            isEnabled: true,
            hour: dailyReminderHour,
            minute: dailyReminderMinute
        )
        helperMessage = "SlipDee will remind you every day at \(timeDisplayText)."
    }

    @MainActor
    private func refreshHelperMessage() async {
        guard isDailyReminderEnabled else {
            helperMessage = nil
            return
        }

        let status = await reminderService.authorizationStatus()
        if status == .denied {
            helperMessage = "Notifications are disabled. Please enable notifications in iOS Settings to use reminders."
        } else {
            helperMessage = "SlipDee will remind you every day at \(timeDisplayText)."
        }
    }

    private var timeDisplayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: makeReminderDate(hour: dailyReminderHour, minute: dailyReminderMinute))
    }

    private func makeReminderDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}
