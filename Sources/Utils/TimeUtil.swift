import Foundation

enum TimeUtil {
    static func now() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

    static func formatDateTime(_ ms: Int64?) -> String {
        guard let ms = ms, ms > 0 else { return "待填写" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    static func formatDate(_ ms: Int64?) -> String {
        guard let ms = ms, ms > 0 else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    static func fileStamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd_HHmmss"
        return fmt.string(from: Date())
    }

    static func year() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        return fmt.string(from: Date())
    }

    static func monthKey(_ ms: Int64) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        return fmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
}
