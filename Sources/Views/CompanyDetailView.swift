import SwiftUI

struct CompanyDetailView: View {
    let companyId: Int64
    @State private var company: Company?
    @State private var showDeleteConfirm = false
    @State private var exportedUrl: URL?
    @State private var showExportSheet = false
    @State private var exportKind = 0 // 0 csv, 1 doc

    var body: some View {
        Group {
            if let c = company {
                detailContent(c)
            } else {
                ProgressView().navigationTitle("加载中...")
            }
        }
        .onAppear { load() }
        .confirmationDialog("删除企业", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                CompanyDao().delete(companyId)
                NotificationCenter.default.post(name: .companyDeleted, object: nil)
            }
            Button("取消", role: .cancel) {}
        } message: { Text("删除后不可恢复，确定删除该企业及其全部备案记录？") }
        .fileExporter(isPresented: $showExportSheet,
                      document: CSVDocument(url: exportedUrl),
                      contentType: exportKind == 0 ? .commaSeparatedText : .data,
                      defaultFilename: exportedUrl?.lastPathComponent ?? "export") { _ in }
    }

    private func detailContent(_ c: Company) -> some View {
        TabView {
            ProcessTimelineView(companyId: companyId)
                .tabItem { Label("备案流程", systemImage: "clock") }
            CompanyInfoView(company: c)
                .tabItem { Label("企业信息", systemImage: "info.circle") }
            AuditView(companyId: companyId)
                .tabItem { Label("修改历史", systemImage: "clock.arrow.circlepath") }
        }
        .navigationTitle(c.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("导出 Excel") { exportCsv(c) }
                    Button("导出 Word") { exportDoc(c) }
                    NavigationLink("编辑企业档案") { CompanyEditView(companyId: companyId) }
                    Button("删除企业", role: .destructive) { showDeleteConfirm = true }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private func load() {
        company = CompanyDao().getById(companyId)
    }

    private func exportCsv(_ c: Company) {
        exportedUrl = ExportService.exportCompanyCsv(c)
        exportKind = 0
        showExportSheet = true
    }

    private func exportDoc(_ c: Company) {
        exportedUrl = ExportService.exportCompanyDoc(c)
        exportKind = 1
        showExportSheet = true
    }
}

extension Notification.Name {
    static let companyDeleted = Notification.Name("companyDeleted")
    static let dataChanged = Notification.Name("dataChanged")
}
