import SwiftUI
import UniformTypeIdentifiers

struct CompanyListView: View {
    @State private var companies: [Company] = []
    @State private var query = ""
    @State private var page = 0
    @State private var hasMore = true
    @State private var loading = false
    @State private var showExport = false
    @State private var exportedUrl: URL?

    private let pageSize = 20

    var body: some View {
        List {
            ForEach(companies) { c in
                NavigationLink(destination: CompanyDetailView(companyId: c.id)) {
                    CompanyRow(c: c)
                }
                .onAppear {
                    if c.id == companies.last?.id && hasMore && !loading {
                        loadMore()
                    }
                }
            }
            if loading { ProgressView().frame(maxWidth: .infinity).padding() }
        }
        .searchable(text: $query, prompt: "搜索企业名称/信用代码/联系人/电话")
        .onSubmit(of: .search) { reload() }
        .onChange(of: query) { _ in reload() }
        .refreshable { reload() }
        .navigationTitle("快件运营人备案管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("导出全部 Excel") { exportAll() }
                } label: { Image(systemName: "ellipsis.circle") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CompanyEditView()) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { reload() }
        .fileExporter(isPresented: $showExport, document: CSVDocument(url: exportedUrl),
                      contentType: .commaSeparatedText, defaultFilename: exportedUrl?.lastPathComponent ?? "export.csv") { _ in }
    }

    private func reload() {
        page = 0; hasMore = true
        load(page: 0, append: false)
    }

    private func loadMore() {
        page += 1
        load(page: page, append: true)
    }

    private func load(page: Int, append: Bool) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let list = CompanyDao().list(query, limit: pageSize, offset: page * pageSize)
            DispatchQueue.main.async {
                if append { companies.append(contentsOf: list) }
                else { companies = list }
                hasMore = list.count >= pageSize
                loading = false
            }
        }
    }

    private func exportAll() {
        if let url = ExportService.exportAllCsv(query: query) {
            exportedUrl = url
            showExport = true
        }
    }
}

struct CompanyRow: View {
    let c: Company
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(c.name).font(.headline).lineLimit(1)
                Spacer()
                StatusBadge(status: c.status)
            }
            Text(c.creditCode).font(.caption).foregroundColor(.secondary)
            Text("更新：\(TimeUtil.formatDateTime(c.updatedAt))").font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: Int
    var body: some View {
        let rgb = Status.color(status)
        Text(Status.name(status))
            .font(.caption2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color(red: rgb.0, green: rgb.1, blue: rgb.2).opacity(0.15))
            .foregroundColor(Color(red: rgb.0, green: rgb.1, blue: rgb.2))
            .cornerRadius(8)
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let url: URL?
    init(url: URL?) { self.url = url }
    init(configuration: ReadConfiguration) throws { url = nil }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url, let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
