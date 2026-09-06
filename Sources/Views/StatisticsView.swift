import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var companies: [Company] = []
    @State private var totalRejects = 0
    @State private var avgDuration: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 指标卡片
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(title: "企业总数", value: "\(companies.count)", color: .blue)
                    MetricCard(title: "进行中", value: "\(inProgressCount)", color: .orange)
                    MetricCard(title: "已完成", value: "\(completedCount)", color: .green)
                    MetricCard(title: "已终止", value: "\(terminatedCount)", color: .gray)
                }
                .padding(.horizontal)

                // 状态分布饼图
                VStack(alignment: .leading, spacing: 8) {
                    Text("备案状态分布").font(.headline).padding(.horizontal)
                    Chart(statusData, id: \.name) { item in
                        SectorMark(
                            angle: .value("数量", item.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            Text("\(item.count)").font(.caption2).foregroundColor(.white)
                        }
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // 月度趋势
                VStack(alignment: .leading, spacing: 8) {
                    Text("近12个月新增企业").font(.headline).padding(.horizontal)
                    Chart(monthlyData, id: \.month) { item in
                        LineMark(x: .value("月份", item.month), y: .value("数量", item.count))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("月份", item.month), y: .value("数量", item.count))
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // 其他指标
                HStack(spacing: 12) {
                    MetricCard(title: "平均打回次数", value: String(format: "%.1f", avgRejects), color: .purple)
                    MetricCard(title: "平均处理时长(天)", value: String(format: "%.0f", avgDuration), color: .teal)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("数据统计")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private var inProgressCount: Int { companies.filter { $0.status < 7 }.count }
    private var completedCount: Int { companies.filter { $0.status == 7 }.count }
    private var terminatedCount: Int { companies.filter { $0.status == 8 }.count }
    private var avgRejects: Double {
        guard !companies.isEmpty else { return 0 }
        return Double(totalRejects) / Double(companies.count)
    }

    private var statusData: [(name: String, count: Int, color: Color)] {
        var result: [(name: String, count: Int, color: Color)] = []
        for i in 0..<Status.names.count {
            let cnt = companies.filter { $0.status == i }.count
            if cnt > 0 {
                let rgb = Status.color(i)
                result.append((Status.names[i], cnt, Color(red: rgb.0, green: rgb.1, blue: rgb.2)))
            }
        }
        return result
    }

    private var monthlyData: [(month: String, count: Int)] {
        let cal = Calendar.current
        var result: [(month: String, count: Int)] = []
        for i in (0..<12).reversed() {
            if let d = cal.date(byAdding: .month, value: -i, to: Date()) {
                let fmt = DateFormatter()
                fmt.dateFormat = "MM"
                let month = fmt.string(from: d)
                let cnt = companies.filter {
                    let created = Date(timeIntervalSince1970: Double($0.createdAt) / 1000)
                    return cal.isDate(created, equalTo: d, toGranularity: .month)
                }.count
                result.append((month, cnt))
            }
        }
        return result
    }

    private func load() {
        companies = CompanyDao().list("", limit: 10000, offset: 0)
        var rejects = 0
        var durations: [Double] = []
        for c in companies {
            if let p = RecordDao().getProcess(companyId: c.id) {
                rejects += RecordDao().list(processId: p.id).filter { $0.type == ModRecord.TYPE_REJECT }.count
                if let apply = p.applyTime, c.status == 7 || c.status == 8 {
                    let last = RecordDao().list(processId: p.id).last?.occurTime ?? p.updatedAt
                    durations.append(Double(last - apply) / 86400000)
                }
            }
        }
        totalRejects = rejects
        avgDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
