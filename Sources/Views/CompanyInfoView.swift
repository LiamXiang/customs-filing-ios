import SwiftUI

struct CompanyInfoView: View {
    let company: Company
    var body: some View {
        List {
            Section("基本信息") {
                row("档案编号", company.code)
                row("企业名称", company.name)
                row("统一社会信用代码", company.creditCode)
                row("企业类型", company.type == 0 ? "境内" : "境外")
                row("联系人", company.contact)
                row("联系电话", company.phone)
                row("企业地址", company.address)
            }
            Section("其他") {
                row("当前状态", Status.name(company.status))
                row("创建时间", TimeUtil.formatDateTime(company.createdAt))
                row("更新时间", TimeUtil.formatDateTime(company.updatedAt))
                if !company.remark.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("备注").font(.caption).foregroundColor(.secondary)
                        Text(company.remark).font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }
}

struct AuditView: View {
    let companyId: Int64
    @State private var logs: [AuditLog] = []
    var body: some View {
        List {
            ForEach(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(log.action).font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        Text(TimeUtil.formatDateTime(log.createdAt)).font(.caption2).foregroundColor(.secondary)
                    }
                    if !log.oldValue.isEmpty {
                        Text("原值：\(log.oldValue)").font(.caption).foregroundColor(.secondary)
                    }
                    if !log.newValue.isEmpty {
                        Text("新值：\(log.newValue)").font(.caption).foregroundColor(.secondary)
                    }
                    Text("操作人：\(log.operatorName)").font(.caption2).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            if logs.isEmpty {
                Text("暂无修改记录").foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear { logs = AuditDao().list(companyId: companyId) }
    }
}
