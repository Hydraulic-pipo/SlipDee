import SwiftUI

struct SlipScanReviewView: View {
    let result: ScannedSlipResult

    var body: some View {
        ConfirmTransactionView(initialResult: result.parsedSlip)
    }
}
