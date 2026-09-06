import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var showBackupPicker = false
    @State private var showBackupExporter = false
    @State private var backupUrl: URL?
    @State private var showMessage = false
    @State private var message = ""
    @State private var lockEnabled = UserDefaults.standard.bool(forKey: "lock_enabled")
    @State private var showPinSetup = false
    @State private var showAbout = false

    var body: some View {
        Form {
            Section("数据管理") {
                Button { backup() } label: {
                    Label("数据备份", systemImage: "arrow.down.doc")
                }
                Button { showBackupPicker = true } label: {
                    Label("数据恢复", systemImage: "arrow.up.doc")
                }
                Button(role: .destructive) { cleanOld() } label: {
                    Label("清理过期数据", systemImage: "trash")
                }
            }

            Section("安全") {
                Toggle(isOn: $lockEnabled) {
                    Label("应用锁（PIN码）", systemImage: "lock")
                }
                .onChange(of: lockEnabled) { v in
                    UserDefaults.standard.set(v, forKey: "lock_enabled")
                    if v { showPinSetup = true }
                }
            }

            Section("关于") {
                Button { showAbout = true } label: {
                    Label("关于与帮助", systemImage: "info.circle")
                }
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0").foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showBackupPicker, allowedContentTypes: [.data]) { result in
            if case .success(let url) = result { restore(url) }
        }
        .fileExporter(isPresented: $showBackupExporter,
                      document: CSVDocument(url: backupUrl),
                      contentType: .data,
                      defaultFilename: backupUrl?.lastPathComponent ?? "backup.db") { _ in
            backupUrl = nil
            showBackupExporter = false
        }
        .alert("提示", isPresented: $showMessage) {
            Button("确定", role: .cancel) {}
        } message: { Text(message) }
        .sheet(isPresented: $showPinSetup) { PinSetupView() }
        .alert("关于", isPresented: $showAbout) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("快件运营人备案管理 iOS 版 v1.0.0\n\n用于记录快件运营人备案流程各节点时间、修改要求及修改情况，支持企业档案管理、备案流程跟踪、数据导出与统计。\n\n数据仅保存在本地设备。")
        }
    }

    private func backup() {
        if let url = ExportService.backup() {
            backupUrl = url
            showBackupExporter = true
        } else {
            message = "备份失败"
            showMessage = true
        }
    }

    private func restore(_ url: URL) {
        if ExportService.restore(from: url) {
            message = "恢复成功"
        } else {
            message = "恢复失败，请确认文件正确"
        }
        showMessage = true
    }

    private func cleanOld() {
        let oneYearAgo = TimeUtil.now() - 365 * 86400 * 1000
        let all = CompanyDao().list("", limit: 10000, offset: 0)
        var count = 0
        for c in all {
            if (c.status == 7 || c.status == 8) && c.updatedAt < oneYearAgo {
                CompanyDao().delete(c.id)
                count += 1
            }
        }
        message = "已清理 \(count) 条超过1年的已完成/终止档案"
        showMessage = true
    }
}

struct PinSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    @State private var confirm = ""
    var body: some View {
        NavigationStack {
            Form {
                SecureField("设置4-6位PIN码", text: $pin)
                    .keyboardType(.numberPad)
                SecureField("确认PIN码", text: $confirm)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("设置应用锁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        if pin.count >= 4 && pin == confirm {
                            UserDefaults.standard.set(pin, forKey: "app_pin")
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
            }
        }
    }
}

struct PinLockView: View {
    let onUnlock: () -> Void
    @State private var pin = ""
    @State private var showError = false
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("请输入应用锁PIN码").font(.headline)
            SecureField("PIN码", text: $pin)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .multilineTextAlignment(.center)
            Button("解锁") {
                let saved = UserDefaults.standard.string(forKey: "app_pin") ?? ""
                if pin == saved {
                    onUnlock()
                } else {
                    showError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pin.isEmpty)
        }
        .padding()
        .alert("PIN码错误", isPresented: $showError) {
            Button("确定", role: .cancel) { pin = "" }
        }
    }
}
