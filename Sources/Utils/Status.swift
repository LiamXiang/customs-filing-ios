import Foundation

enum Status {
    static let names = [
        "待申请", "已申请待发函", "已发函待总署回复", "总署打回修改中",
        "行邮处处理中", "福中海关修改中", "已反馈总署", "备案完成", "备案终止"
    ]
    static func name(_ s: Int) -> String {
        if s >= 0 && s < names.count { return names[s] }
        return "未知"
    }
    static func color(_ s: Int) -> (Double, Double, Double) {
        switch s {
        case 7: return (0.18, 0.68, 0.38)  // 绿 完成
        case 8: return (0.55, 0.55, 0.55)  // 灰 终止
        case 3: return (0.90, 0.45, 0.12)  // 橙 打回
        default: return (0.10, 0.45, 0.85) // 蓝 进行中
        }
    }
}
