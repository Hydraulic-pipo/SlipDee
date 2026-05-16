import SwiftUI

struct EditTransactionView: View {
    let transaction: TransactionItem

    var body: some View {
        ManualTransactionFormView(mode: .edit(transaction))
    }
}
