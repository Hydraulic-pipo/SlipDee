import Foundation

struct SpendingInsightProvider {
    static func insight(
        currentMonthExpense: Double,
        previousMonthExpense: Double,
        topCategoryName: String? = nil
    ) -> String {
        if currentMonthExpense == 0, previousMonthExpense == 0 {
            return "ยังไม่มีข้อมูลรายจ่าย ลองเพิ่มรายการหรือสแกนสลิปเพื่อดู Insight ครับ"
        }

        if previousMonthExpense == 0, currentMonthExpense > 0 {
            return "เริ่มมีข้อมูลรายจ่ายของเดือนนี้แล้ว เมื่อมีข้อมูลเดือนก่อน SlipDee จะช่วยเปรียบเทียบให้ครับ"
        }

        if currentMonthExpense < previousMonthExpense {
            let decrease = ((previousMonthExpense - currentMonthExpense) / previousMonthExpense) * 100
            let rounded = Int(decrease.rounded())
            return "เดือนนี้คุณใช้จ่ายน้อยลง \(rounded)% จากเดือนที่แล้ว ดีมากครับ 😊"
        }

        if currentMonthExpense > previousMonthExpense {
            let increase = ((currentMonthExpense - previousMonthExpense) / previousMonthExpense) * 100
            let rounded = Int(increase.rounded())

            if let topCategoryName, !topCategoryName.isEmpty {
                return "เดือนนี้คุณใช้จ่ายเพิ่มขึ้น \(rounded)% จากเดือนที่แล้ว โดยหมวดที่ใช้มากที่สุดคือ \(topCategoryName)"
            }

            return "เดือนนี้คุณใช้จ่ายเพิ่มขึ้น \(rounded)% จากเดือนที่แล้ว ลองตรวจดูหมวดที่ใช้เยอะที่สุดครับ"
        }

        return "เดือนนี้คุณใช้จ่ายใกล้เคียงกับเดือนที่แล้ว"
    }
}
