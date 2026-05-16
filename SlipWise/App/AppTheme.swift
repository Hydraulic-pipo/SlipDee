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

    init(dynamicLight: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : dynamicLight
        })
    }
}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppColors {
    static let background = Color(
        dynamicLight: UIColor(red: 248 / 255, green: 250 / 255, blue: 252 / 255, alpha: 1),
        dark: UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 1)
    )
    static let cardBackground = Color(
        dynamicLight: .white,
        dark: UIColor(red: 30 / 255, green: 41 / 255, blue: 59 / 255, alpha: 1)
    )
    static let elevatedCardBackground = Color(
        dynamicLight: UIColor(red: 241 / 255, green: 245 / 255, blue: 249 / 255, alpha: 1),
        dark: UIColor(red: 36 / 255, green: 50 / 255, blue: 68 / 255, alpha: 1)
    )
    static let primaryTeal = Color(
        dynamicLight: UIColor(red: 20 / 255, green: 184 / 255, blue: 166 / 255, alpha: 1),
        dark: UIColor(red: 45 / 255, green: 212 / 255, blue: 191 / 255, alpha: 1)
    )
    static let darkTeal = Color(
        dynamicLight: UIColor(red: 15 / 255, green: 118 / 255, blue: 110 / 255, alpha: 1),
        dark: UIColor(red: 20 / 255, green: 184 / 255, blue: 166 / 255, alpha: 1)
    )
    static let softTealBackground = Color(
        dynamicLight: UIColor(red: 204 / 255, green: 251 / 255, blue: 241 / 255, alpha: 1),
        dark: UIColor(red: 19 / 255, green: 78 / 255, blue: 74 / 255, alpha: 1)
    )
    static let softMint = softTealBackground
    static let primaryText = Color(
        dynamicLight: UIColor(red: 15 / 255, green: 23 / 255, blue: 42 / 255, alpha: 1),
        dark: UIColor(red: 248 / 255, green: 250 / 255, blue: 252 / 255, alpha: 1)
    )
    static let secondaryText = Color(
        dynamicLight: UIColor(red: 100 / 255, green: 116 / 255, blue: 139 / 255, alpha: 1),
        dark: UIColor(red: 203 / 255, green: 213 / 255, blue: 225 / 255, alpha: 1)
    )
    static let mutedText = Color(
        dynamicLight: UIColor(red: 148 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1),
        dark: UIColor(red: 148 / 255, green: 163 / 255, blue: 184 / 255, alpha: 1)
    )
    static let border = Color(
        dynamicLight: UIColor(red: 226 / 255, green: 232 / 255, blue: 240 / 255, alpha: 1),
        dark: UIColor(red: 51 / 255, green: 65 / 255, blue: 85 / 255, alpha: 1)
    )
    static let income = Color(
        dynamicLight: UIColor(red: 22 / 255, green: 163 / 255, blue: 74 / 255, alpha: 1),
        dark: UIColor(red: 74 / 255, green: 222 / 255, blue: 128 / 255, alpha: 1)
    )
    static let expense = Color(
        dynamicLight: UIColor(red: 249 / 255, green: 115 / 255, blue: 115 / 255, alpha: 1),
        dark: UIColor(red: 251 / 255, green: 113 / 255, blue: 133 / 255, alpha: 1)
    )
    static let warning = Color(
        dynamicLight: UIColor(red: 245 / 255, green: 158 / 255, blue: 11 / 255, alpha: 1),
        dark: UIColor(red: 251 / 255, green: 191 / 255, blue: 36 / 255, alpha: 1)
    )
    static let shadow = Color(
        dynamicLight: UIColor.black.withAlphaComponent(0.05),
        dark: UIColor.black.withAlphaComponent(0.18)
    )
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
    static let cardColor = AppColors.shadow
    static let cardRadius: CGFloat = 18
    static let cardYOffset: CGFloat = 8
}

enum AppTheme {
    static let navy = AppColors.primaryTeal
    static let navySecondary = AppColors.darkTeal
    static let cardBackground = AppColors.cardBackground
    static let cardSecondary = AppColors.elevatedCardBackground
    static let mint = AppColors.primaryTeal
    static let cyan = AppColors.softTealBackground
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
                    .background(AppColors.softTealBackground)
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
                .background(AppColors.elevatedCardBackground)
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
            .background(AppColors.elevatedCardBackground)
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
                .background(AppColors.softTealBackground)
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
