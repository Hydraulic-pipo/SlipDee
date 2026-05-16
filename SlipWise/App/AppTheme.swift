import SwiftUI

extension Color {
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

enum AppColors {
    static let background = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
    static let cardBackground = Color.white
    static let primaryTeal = Color(red: 20 / 255, green: 184 / 255, blue: 166 / 255)
    static let darkTeal = Color(red: 15 / 255, green: 118 / 255, blue: 110 / 255)
    static let softMint = Color(red: 204 / 255, green: 251 / 255, blue: 241 / 255)
    static let primaryText = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let secondaryText = Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255)
    static let mutedText = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let border = Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255)
    static let income = Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)
    static let expense = Color(red: 249 / 255, green: 115 / 255, blue: 115 / 255)
    static let warning = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
}

enum AppSpacing {
    static let page: CGFloat = 20
    static let section: CGFloat = 24
    static let card: CGFloat = 16
    static let item: CGFloat = 12
    static let compact: CGFloat = 8
}

enum AppCornerRadius {
    static let large: CGFloat = 28
    static let medium: CGFloat = 22
    static let small: CGFloat = 16
}

enum AppShadow {
    static let cardColor = Color.black.opacity(0.05)
    static let cardRadius: CGFloat = 18
    static let cardYOffset: CGFloat = 8
}

enum AppTheme {
    static let navy = AppColors.primaryTeal
    static let navySecondary = AppColors.darkTeal
    static let cardBackground = AppColors.cardBackground
    static let cardSecondary = AppColors.background
    static let mint = AppColors.primaryTeal
    static let cyan = AppColors.softMint
    static let ink = AppColors.primaryText
    static let mutedInk = AppColors.secondaryText
    static let positive = AppColors.income
    static let warning = AppColors.warning
    static let danger = AppColors.expense

    static let pagePadding = AppSpacing.page
    static let cardRadius = AppCornerRadius.medium
    static let cardSpacing = AppSpacing.card
}

struct AppScreen<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            content
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            .shadow(color: AppShadow.cardColor, radius: AppShadow.cardRadius, x: 0, y: AppShadow.cardYOffset)
    }
}

struct AmountSummaryCard: View {
    let title: String
    let amount: String
    let subtitle: String
    let accent: Color
    let icon: String
    var emphasized = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(accent)
                        .frame(width: 40, height: 40)
                        .background(accent.opacity(0.12))
                        .clipShape(Circle())

                    Spacer()
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(amount)
                    .font(emphasized ? .system(size: 32, weight: .bold, design: .rounded) : .system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedText)
            }
        }
    }
}

struct AppSectionHeader: View {
    let title: String
    let subtitle: String?
    var trailing: String?

    init(_ title: String, subtitle: String? = nil, trailing: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryTeal)
            }
        }
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        AppCard {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.darkTeal)
                    .frame(width: 56, height: 56)
                    .background(AppColors.softMint)
                    .clipShape(Circle())

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

struct PrimaryFintechButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primaryTeal.opacity(configuration.isPressed ? 0.88 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct SecondaryFintechButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppColors.primaryTeal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct AppInputField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboardType)
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
    }
}

struct AppPickerField<Content: View, SelectionValue: Hashable>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content

    init(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Picker(title, selection: $selection) {
                content
            }
            .tint(AppColors.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailingText: String?
    let showsChevron: Bool

    init(icon: String, title: String, subtitle: String? = nil, trailingText: String? = nil, showsChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingText = trailingText
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.darkTeal)
                .frame(width: 34, height: 34)
                .background(AppColors.softMint)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedText)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
            }
        }
    }
}
