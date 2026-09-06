import SwiftUI

struct CompanyEditView: View {
    var companyId: Int64?
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var creditCode = ""
    @State private var type = 0
    @State private var address = ""
    @State private var contact = ""
    @State private var phone = ""
    @State private var remark = ""
    @State private var showError = false
    @State private var errorMsg = ""

    var isEdit: Bool { companyId != nil }

    var body: some View {
        Form {
            Section("基本信息") {
                HStack { Text("企业名称"); Spacer(); Text("*").foregroundColor(.red) }
                TextField("请输入企业名称", text: $name)
                HStack { Text("统一社会信用代码"); Spacer(); Text("*").foregroundColor(.red) }
                TextField("18位统一社会信用代码", text: $creditCode)
                Picker("企业类型", selection: $type) {
                    Text("境内").tag(0)
                    Text("境外").tag(1)
                }
                TextField("企业地址", text: $address)
                TextField("联系人", text: $contact)
                TextField("联系电话", text: $phone)
            }
            Section("备注") {
                TextEditor(text: $remark).frame(minHeight: 80)
            }
        }
        .navigationTitle(isEdit ? "编辑企业" : "新增企业")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { save() }
            }
        }
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: { Text(errorMsg) }
        .onAppear { load() }
    }

    private func load() {
        guard let id = companyId, let c = CompanyDao().getById(id) else { return }
        name = c.name; creditCode = c.creditCode; type = c.type
        address = c.address; contact = c.contact; phone = c.phone; remark = c.remark
    }

    private func save() {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMsg = "请输入企业名称"; showError = true; return
        }
        if creditCode.trimmingCharacters(in: .whitespaces).count != 18 {
            errorMsg = "统一社会信用代码应为18位"; showError = true; return
        }
        if isEdit, let id = companyId, var c = CompanyDao().getById(id) {
            c.name = name; c.creditCode = creditCode; c.type = type
            c.address = address; c.contact = contact; c.phone = phone; c.remark = remark
            CompanyDao().update(c)
            AuditDao().log(companyId: id, entityType: "company", entityId: id,
                           action: "编辑企业", old: "", new: name)
        } else {
            var c = Company()
            c.name = name; c.creditCode = creditCode; c.type = type
            c.address = address; c.contact = contact; c.phone = phone; c.remark = remark
            let id = CompanyDao().insert(&c)
            AuditDao().log(companyId: id, entityType: "company", entityId: id,
                           action: "新增企业", old: "", new: name)
        }
        NotificationCenter.default.post(name: .dataChanged, object: nil)
        dismiss()
    }
}
