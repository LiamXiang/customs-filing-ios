import SwiftUI

struct ProcessTimelineView: View {
    let companyId: Int64
    @State private var process: FilingProcess?
    @State private var records: [ModRecord] = []
    @State private var showStatusPicker = false
    @State private var showRecordDialog = false
    @State private var editingRecord: ModRecord?
    @State private var dialogType = 0

    var body: some View {
        List {
            if var p = process {
                Section {
                    HStack {
                        Text("当前状态")
                        Spacer()
                        StatusBadge(status: p.status)
                        Button("更新状态") { showStatusPicker = true }
                            .font(.subheadline)
                    }
                }

                // 固定节点
                Section {
                    TimelineNode(title: "企业申请备案时间",
                                 time: p.applyTime,
                                 onTap: { pickTime { p.applyTime = $0; process = p; saveProcess() } })
                    TimelineNode(title: "深圳海关发函给总署时间",
                                 time: p.sendToGaccTime,
                                 onTap: { pickTime { p.sendToGaccTime = $0; process = p; saveProcess() } })
                }

                // 四类可多次添加的记录
                recordSection(type: ModRecord.TYPE_REJECT, title: "总署打回修改")
                recordSection(type: ModRecord.TYPE_CONTACT_FZ, title: "行邮处联系福中海关修改")
                recordSection(type: ModRecord.TYPE_FZ_FEEDBACK, title: "福中海关修改反馈行邮处")
                recordSection(type: ModRecord.TYPE_GACC_FEEDBACK, title: "行邮处反馈总署")
            }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .dataChanged)) { _ in reload() }
        .sheet(isPresented: $showStatusPicker) {
            StatusPickerView(current: process?.status ?? 0) { newStatus in
                if var p = process {
                    let old = Status.name(p.status)
                    p.status = newStatus
                    RecordDao().updateStatus(processId: p.id, status: newStatus)
                    AuditDao().log(companyId: companyId, entityType: "process", entityId: p.id,
                                   action: "更新备案状态", old: old, new: Status.name(newStatus))
                    reload()
                }
                showStatusPicker = false
            }
        }
        .sheet(isPresented: $showRecordDialog) {
            RecordEditView(record: editingRecord, type: dialogType, processId: process?.id ?? 0, companyId: companyId) {
                reload()
            }
        }
    }

    private func recordSection(type: Int, title: String) -> some View {
        let list = records.filter { $0.type == type }
        return Section {
            ForEach(list) { r in
                RecordRow(r: r) {
                    editingRecord = r
                    dialogType = type
                    showRecordDialog = true
                }
            }
            Button {
                editingRecord = nil
                dialogType = type
                showRecordDialog = true
            } label: {
                Label("添加", systemImage: "plus.circle")
                    .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.85))
            }
        } header: {
            Text("\(title)（\(list.count)次）")
        }
    }

    private func reload() {
        process = RecordDao().getProcess(companyId: companyId)
        if let p = process {
            records = RecordDao().list(processId: p.id)
        }
    }

    private func saveProcess() {
        if var p = process { RecordDao().updateProcess(p) }
    }

    private func pickTime(completion: @escaping (Int64) -> Void) {
        let vc = UIHostingController(rootView: TimePickerView { t in
            completion(t)
            UIApplication.shared.windows.first?.rootViewController?.presentedViewController?.dismiss(animated: true)
        })
        vc.modalPresentationStyle = .formSheet
        UIApplication.shared.windows.first?.rootViewController?.present(vc, animated: true)
    }
}

struct TimelineNode: View {
    let title: String
    let time: Int64?
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline).foregroundColor(.primary)
                    Text(TimeUtil.formatDateTime(time))
                        .font(.caption)
                        .foregroundColor(time == nil ? .secondary : .primary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
            }
            .padding(.vertical, 4)
        }
    }
}

struct RecordRow: View {
    let r: ModRecord
    let onEdit: () -> Void
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 4) {
                Text(TimeUtil.formatDateTime(r.occurTime)).font(.caption).foregroundColor(.secondary)
                Text(r.content).font(.subheadline).lineLimit(2)
                if !r.remark.isEmpty {
                    Text("备注：\(r.remark)").font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct TimePickerView: View {
    let onConfirm: (Int64) -> Void
    @State private var date = Date()
    var body: some View {
        NavigationStack {
            DatePicker("选择时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("选择时间")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("确定") {
                            onConfirm(Int64(date.timeIntervalSince1970 * 1000))
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") {
                            UIApplication.shared.windows.first?.rootViewController?.presentedViewController?.dismiss(animated: true)
                        }
                    }
                }
        }
    }
}
