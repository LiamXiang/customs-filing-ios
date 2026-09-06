import Foundation

struct FilingProcess {
    var id: Int64 = 0
    var companyId: Int64 = 0
    var status: Int = 0
    var applyTime: Int64? = nil
    var sendToGaccTime: Int64? = nil
    var createdAt: Int64 = 0
    var updatedAt: Int64 = 0
}

struct ModRecord: Identifiable {
    static let TYPE_REJECT = 1        // 总署打回
    static let TYPE_CONTACT_FZ = 2    // 行邮处联系福中
    static let TYPE_FZ_FEEDBACK = 3   // 福中反馈行邮
    static let TYPE_GACC_FEEDBACK = 4 // 行邮反馈总署

    var id: Int64 = 0
    var processId: Int64 = 0
    var type: Int = 0
    var occurTime: Int64 = 0
    var content: String = ""
    var remark: String = ""
    var createdAt: Int64 = 0
}

struct AuditLog: Identifiable {
    var id: Int64 = 0
    var entityType: String = ""
    var entityId: Int64 = 0
    var action: String = ""
    var oldValue: String = ""
    var newValue: String = ""
    var operatorName: String = "本机用户"
    var createdAt: Int64 = 0
}
