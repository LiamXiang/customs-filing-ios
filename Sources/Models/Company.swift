import Foundation

struct Company: Identifiable {
    var id: Int64 = 0
    var code: String = ""
    var name: String = ""
    var creditCode: String = ""
    var type: Int = 0 // 0境内 1境外
    var address: String = ""
    var contact: String = ""
    var phone: String = ""
    var remark: String = ""
    var createdAt: Int64 = 0
    var updatedAt: Int64 = 0
    var status: Int = 0
}
