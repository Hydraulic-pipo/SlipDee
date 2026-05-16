import Foundation
import SwiftData

enum DemoDataSeeder {
    @MainActor
    static func seedIfNeeded(container: ModelContainer) async {
        let context = container.mainContext
        let transactionDescriptor = FetchDescriptor<TransactionItem>()
        let categoryDescriptor = FetchDescriptor<TransactionCategory>()
        let settingsDescriptor = FetchDescriptor<UserSettings>()

        let existingCategoryCount = (try? context.fetchCount(categoryDescriptor)) ?? 0
        if existingCategoryCount == 0 {
            TransactionCategoryCatalog.defaultModels().forEach(context.insert)
        }

        let existingSettingsCount = (try? context.fetchCount(settingsDescriptor)) ?? 0
        if existingSettingsCount == 0 {
            context.insert(UserSettings())
        }

        let existingTransactionCount = (try? context.fetchCount(transactionDescriptor)) ?? 0
        guard existingTransactionCount == 0 else {
            try? context.save()
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let salaryCategory = TransactionCategoryCatalog.definition(named: "Salary")
        let foodCategory = TransactionCategoryCatalog.definition(named: "Food & Drink")
        let transportCategory = TransactionCategoryCatalog.definition(named: "Transport")
        let entertainmentCategory = TransactionCategoryCatalog.definition(named: "Entertainment")

        let demoTransactions = [
            TransactionItem(
                categoryDefinition: salaryCategory,
                amount: 1200,
                type: .income,
                paymentMethod: .bankTransfer,
                merchantName: "SlipDee Demo Co.",
                bankName: "Bangkok Bank",
                receiverName: "SlipDee Demo Co.",
                senderName: "SlipDee Payroll",
                transactionReference: "SAL20260501",
                transactionDate: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                note: "Demo salary payment",
                sourceImageName: "demo_salary_slip.jpg"
            ),
            TransactionItem(
                categoryDefinition: foodCategory,
                amount: 145,
                type: .expense,
                paymentMethod: .promptPay,
                merchantName: "Cafe Riverside",
                bankName: "KBank",
                receiverName: "Cafe Riverside",
                senderName: "SlipDee Demo User",
                transactionReference: "FOOD20260510",
                transactionDate: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                note: "Iced latte and snack",
                sourceImageName: "demo_coffee_slip.jpg"
            ),
            TransactionItem(
                categoryDefinition: transportCategory,
                amount: 58,
                type: .expense,
                paymentMethod: .qrPayment,
                merchantName: "Metro Line",
                bankName: "SCB",
                receiverName: "Metro Line",
                senderName: "SlipDee Demo User",
                transactionReference: "TRIP20260511",
                transactionDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                note: "Train fare",
                sourceImageName: "demo_train_slip.jpg"
            ),
            TransactionItem(
                categoryDefinition: entertainmentCategory,
                amount: 499,
                type: .expense,
                paymentMethod: .card,
                merchantName: "Movie World",
                bankName: "Krungthai",
                receiverName: "Movie World",
                senderName: "SlipDee Demo User",
                transactionReference: "FUN20260512",
                transactionDate: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                note: "Weekend movie tickets",
                sourceImageName: "demo_movie_slip.jpg"
            )
        ]

        demoTransactions.forEach(context.insert)

        try? context.save()
    }
}
