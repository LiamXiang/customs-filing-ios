import SwiftUI

struct RecordEditView: View {
    var record: ModRecord?
    var type: Int
    var processId: Int64
    var companyId: Int64
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var occurTime: Int64 = 0
    @State private var content = ""
    @State private var remark = ""
    @State private var showTimePicker = false
    @State private var showError = false
    @State private var errorMsg = ""

    var isEdit: Bool { record != nil }
    var contentLabel: String { ExportService.contentLabel(type) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { showTimePicker = true } label: {
                        HStack {
                            Text("发生时间")
                            Spacer()
                            Text(occurTime > 0 ? TimeUtil.formatDateTime(occurTime) : "点击选择时间")
                                .foregroundColor(occurTime > 0 ? .primary : .secondary)
                        }
                    }
                }
                Section(contentLabel) {
                    TextEditor(text: $content).frame(minHeight: 100)
                }
                Section("备注（选填）") {
                    TextField("备注", text: $remark)
                }
            }
            .navigationTitle(isEdit ? "编辑记录" : "添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                }
                if isEdit {
                    ToolbarItem(placement: .bottomBar) {
                        Button("删除此记录", role: .destructive) { delete() }
                    }
                }
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerView { t in
                    occurTime = t
                    showTimePicker = false
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: { Text(errorMsg) }
            .onAppear {
                if let r = record {
                    occurTime = r.occurTime; content = r.content; remark = r.remark
                }
            }
        }
    }

    private func save() {
        if occurTime <= 0 { errorMsg = "请选择发生时间"; showError = true; return }
        if content.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMsg = "请填写\(contentLabel)"; showError = true; return
        }
        if var r = record {
            r.occurTime = occurTime; r.content = content; r.remark = remark
            RecordDao().update(r)
            AuditDao().log(companyId: companyId, entityType: "record", entityId: r.id,
                           action: "编辑记录", old: "", new: "\(TimeUtil.formatDateTime(occurTime)) \(content)")
        } else {
            var r = ModRecord()
            r.processId = processId; r.type = type
            r.occurTime = occurTime; r.content = content; r.remark = remark
            let id = RecordDao().insert(r)
            AuditDao().log(companyId: companyId, entityType: "record", entityId: id,
                           action: "新增记录", old: "", new: "\(TimeUtil.formatDateTime(occurTime)) \(content)")
        }
        onDone()
        dismiss()
    }

    private func delete() {
        guard let r = record else { return }
        RecordDao().delete(r.id)
        AuditDao().log(companyId: companyId, entityType: "record", entityId: r.id,
                       action: "删除记录", old: TimeUtil.formatDateTime(r.occurTime), new: "")
        onDone()
        dismiss()
    }
}

struct StatusPickerView: View {
    let current: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(0..<Status.names.count, id: \.self) { i in
                Button {
                    onSelect(i)
                } label: {
                    HStack {
                        StatusBadge(status: i)
                        Spacer()
                        if i == current { Image(systemName: "checkmark").foregroundColor(.blue) }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("选择备案状态")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
            }
        }
    }
}
