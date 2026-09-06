import Foundation
import UIKit

/// 导出服务：Excel(CSV) / Word(HTML) / 备份
enum ExportService {

    /// 导出全部企业为 CSV（Excel 可直接打开）
    static func exportAllCsv(query: String = "") -> URL? {
        let companies = CompanyDao().list(query, limit: 10000, offset: 0)
        var csv = "序号,企业名称,统一社会信用代码,企业类型,联系人,联系电话,申请时间,发函总署时间,总署打回次数,最近打回时间,最近打回要求,行邮联系福中次数,最近联系时间,最近联系内容,福中反馈次数,最近反馈时间,最近反馈情况,行邮反馈总署次数,最近反馈时间,最近反馈情况,当前状态,备注\n"
        for (i, c) in companies.enumerated() {
            let info = companySummary(c)
            csv += "\(i+1),\(esc(c.name)),\(esc(c.creditCode)),\(c.type==0 ? "境内":"境外"),\(esc(c.contact)),\(esc(c.phone)),\(info.applyTime),\(info.sendTime),\(info.rejectCount),\(info.lastRejectTime),\(esc(info.lastRejectContent)),\(info.contactCount),\(info.lastContactTime),\(esc(info.lastContactContent)),\(info.fzCount),\(info.lastFzTime),\(esc(info.lastFzContent)),\(info.gaccCount),\(info.lastGaccTime),\(esc(info.lastGaccContent)),\(Status.name(c.status)),\(esc(c.remark))\n"
        }
        return save(csv.data(using: .utf8) ?? Data(), name: "快件运营人备案台账_总表_\(TimeUtil.fileStamp()).csv")
    }

    /// 导出单个企业为 CSV
    static func exportCompanyCsv(_ company: Company) -> URL? {
        let info = companySummary(company)
        var csv = "字段,内容\n"
        csv += "企业名称,\(esc(company.name))\n"
        csv += "档案编号,\(company.code)\n"
        csv += "统一社会信用代码,\(esc(company.creditCode))\n"
        csv += "企业类型,\(company.type==0 ? "境内":"境外")\n"
        csv += "联系人,\(esc(company.contact))\n"
        csv += "联系电话,\(esc(company.phone))\n"
        csv += "地址,\(esc(company.address))\n"
        csv += "当前状态,\(Status.name(company.status))\n"
        csv += "备注,\(esc(company.remark))\n"
        csv += "\n备案流程记录\n"
        csv += "节点,时间,内容,备注\n"
        if let p = RecordDao().getProcess(companyId: company.id) {
            csv += "企业申请备案,\(TimeUtil.formatDateTime(p.applyTime)),,\n"
            csv += "深圳海关发函总署,\(TimeUtil.formatDateTime(p.sendToGaccTime)),,\n"
            for r in RecordDao().list(p.id) {
                let label = recordLabel(r.type)
                csv += "\(label),\(TimeUtil.formatDateTime(r.occurTime)),\(esc(r.content)),\(esc(r.remark))\n"
            }
        }
        return save(csv.data(using: .utf8) ?? Data(), name: "\(company.name)_备案台账_\(TimeUtil.fileStamp()).csv")
    }

    /// 导出单个企业为 Word（HTML 格式，.doc 后缀，Word/WPS 可打开）
    static func exportCompanyDoc(_ company: Company) -> URL? {
        let info = companySummary(company)
        var html = """
        <html><head><meta charset="utf-8"><style>
        body{font-family:"Microsoft YaHei",sans-serif;font-size:14px;}
        h1{text-align:center;font-size:20px;}
        table{border-collapse:collapse;width:100%;margin:10px 0;}
        td,th{border:1px solid #333;padding:6px 10px;}
        th{background:#f0f0f0;}
        .timeline{margin:10px 0;}
        .node{margin:8px 0;padding-left:16px;border-left:3px solid #1976D2;}
        </style></head><body>
        <h1>快件运营人备案进度记录表</h1>
        <table>
        <tr><th>企业名称</th><td>\(esc(company.name))</td><th>档案编号</th><td>\(company.code)</td></tr>
        <tr><th>统一社会信用代码</th><td>\(esc(company.creditCode))</td><th>企业类型</th><td>\(company.type==0 ? "境内":"境外")</td></tr>
        <tr><th>联系人</th><td>\(esc(company.contact))</td><th>联系电话</th><td>\(esc(company.phone))</td></tr>
        <tr><th>地址</th><td colspan="3">\(esc(company.address))</td></tr>
        <tr><th>当前状态</th><td>\(Status.name(company.status))</td><th>备注</th><td>\(esc(company.remark))</td></tr>
        </table>
        <h3>备案流程时间轴</h3>
        <div class="timeline">
        """
        if let p = RecordDao().getProcess(companyId: company.id) {
            html += "<div class='node'><b>企业申请备案：</b>\(TimeUtil.formatDateTime(p.applyTime))</div>"
            html += "<div class='node'><b>深圳海关发函总署：</b>\(TimeUtil.formatDateTime(p.sendToGaccTime))</div>"
            for r in RecordDao().list(p.id) {
                html += "<div class='node'><b>\(recordLabel(r.type))：</b>\(TimeUtil.formatDateTime(r.occurTime))，\(esc(r.content))</div>"
            }
        }
        html += "</div></body></html>"
        return save(html.data(using: .utf8) ?? Data(), name: "\(company.name)_备案进度记录_\(TimeUtil.fileStamp()).doc")
    }

    // MARK: - 备份

    static func backup() -> URL? {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbPath = (dir as NSString).appendingPathComponent("filing.db")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)) else { return nil }
        return save(data, name: "备案数据备份_\(TimeUtil.fileStamp()).db")
    }

    static func restore(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let dbPath = (dir as NSString).appendingPathComponent("filing.db")
        Database.shared.close()
        do {
            try data.write(to: URL(fileURLWithPath: dbPath), options: .atomic)
            Database.shared.open()
            return true
        } catch {
            Database.shared.open()
            return false
        }
    }

    // MARK: - 内部

    struct Summary {
        var applyTime = "", sendTime = ""
        var rejectCount = 0, lastRejectTime = "", lastRejectContent = ""
        var contactCount = 0, lastContactTime = "", lastContactContent = ""
        var fzCount = 0, lastFzTime = "", lastFzContent = ""
        var gaccCount = 0, lastGaccTime = "", lastGaccContent = ""
    }

    static func companySummary(_ c: Company) -> Summary {
        var s = Summary()
        guard let p = RecordDao().getProcess(companyId: c.id) else { return s }
        s.applyTime = TimeUtil.formatDateTime(p.applyTime)
        s.sendTime = TimeUtil.formatDateTime(p.sendToGaccTime)
        let records = RecordDao().list(p.id)
        for r in records {
            let t = TimeUtil.formatDateTime(r.occurTime)
            switch r.type {
            case ModRecord.TYPE_REJECT:
                s.rejectCount += 1; s.lastRejectTime = t; s.lastRejectContent = r.content
            case ModRecord.TYPE_CONTACT_FZ:
                s.contactCount += 1; s.lastContactTime = t; s.lastContactContent = r.content
            case ModRecord.TYPE_FZ_FEEDBACK:
                s.fzCount += 1; s.lastFzTime = t; s.lastFzContent = r.content
            default:
                s.gaccCount += 1; s.lastGaccTime = t; s.lastGaccContent = r.content
            }
        }
        return s
    }

    static func recordLabel(_ type: Int) -> String {
        switch type {
        case ModRecord.TYPE_REJECT: return "总署打回修改"
        case ModRecord.TYPE_CONTACT_FZ: return "行邮处联系福中海关"
        case ModRecord.TYPE_FZ_FEEDBACK: return "福中海关反馈行邮处"
        default: return "行邮处反馈总署"
        }
    }

    static func contentLabel(_ type: Int) -> String {
        switch type {
        case ModRecord.TYPE_REJECT: return "修改要求"
        case ModRecord.TYPE_CONTACT_FZ: return "修改内容"
        default: return "反馈情况"
        }
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: "，")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func save(_ data: Data, name: String) -> URL? {
        let dir = NSTemporaryDirectory()
        let path = (dir as NSString).appendingPathComponent(name)
        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
