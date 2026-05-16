import SwiftUI

private enum AppTab: Hashable {
    case home
    case reports
    case transactions
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showingAddActions = false
    @State private var showingManualEntry = false
    @State private var showingSlipImport = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.cardBackground)
        appearance.shadowColor = UIColor(AppColors.border)

        let selectedColor = UIColor(AppColors.primaryTeal)
        let normalColor = UIColor(AppColors.mutedText)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardView()
                }
                .tag(AppTab.home)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationStack {
                    ReportsView()
                }
                .tag(AppTab.reports)
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

                NavigationStack {
                    TransactionListView()
                }
                .tag(AppTab.transactions)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }

                NavigationStack {
                    SettingsView()
                }
                .tag(AppTab.settings)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
            }
            .tint(AppColors.primaryTeal)

            addButton
        }
        .confirmationDialog("Add Transaction", isPresented: $showingAddActions, titleVisibility: .visible) {
            Button("Scan Slip") {
                showingSlipImport = true
            }

            Button("Add Manually") {
                showingManualEntry = true
            }

            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualTransactionFormView()
        }
        .sheet(isPresented: $showingSlipImport) {
            NavigationStack {
                ScanSlipView()
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddActions = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppColors.primaryTeal)
                .clipShape(Circle())
                .shadow(color: AppColors.primaryTeal.opacity(0.25), radius: 16, x: 0, y: 8)
        }
        .offset(y: -18)
        .accessibilityLabel("Add transaction")
    }
}
