import Foundation

struct SlipParserSampleCase: Identifiable {
    let id = UUID()
    let title: String
    let lines: [String]
}

enum SlipParserSamples {
    static let sampleCases: [SlipParserSampleCase] = [
        SlipParserSampleCase(
            title: "KBank PromptPay Transfer",
            lines: [
                "KBank",
                "โอนเงินสำเร็จ",
                "จำนวนเงิน ฿450.00",
                "วันที่ 14 May 2026",
                "เวลา 08:41",
                "จาก: Narin Demo",
                "ถึง: Mali Coffee Shop",
                "Transaction ID: KBMVP202605140841",
                "PromptPay"
            ]
        ),
        SlipParserSampleCase(
            title: "SCB Thai Date Format",
            lines: [
                "ไทยพาณิชย์",
                "รับเงินสำเร็จ",
                "450.00 บาท",
                "14/05/2026 19:20",
                "ผู้โอน: Arun Fiction",
                "ผู้รับ: Ploy Market",
                "หมายเลขอ้างอิง 20260514001920",
                "โอนเงิน"
            ]
        ),
        SlipParserSampleCase(
            title: "Krungthai Buddhist Year",
            lines: [
                "กรุงไทย",
                "THB 1,250.00",
                "14 พ.ค. 2569",
                "เวลา 07:05",
                "จากบัญชี: Green Studio",
                "ชื่อผู้รับ: Demo Rent Office",
                "เลขที่รายการ KTBA256905140705",
                "QR Payment"
            ]
        )
    ]

    static func parsedResults(using parser: SlipParserService = SlipParserService()) -> [ParsedSlip] {
        sampleCases.map { parser.parse(textLines: $0.lines) }
    }
}
