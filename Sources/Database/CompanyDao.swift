import Foundation

final class CompanyDao {
    private let db = Database.shared

    func generateCode() -> String {
        let year = TimeUtil.year()
        let rows = db.query(
            "SELECT code FROM company WHERE code LIKE ? ORDER BY code DESC LIMIT 1",
            [year + "%"])
        var seq = 0
        if let last = rows.first?["code"] as? String {
            seq = Int(last.suffix(4)) ?? 0
        }
        return year + String(format: "%04d", seq + 1)
    }

    func insert(_ c: inout Company) -> Int64 {
        let now = TimeUtil.now()
        c.code = generateCode()
        c.createdAt = now
        c.updatedAt = now
        let id = db.execute("""
            INSERT INTO company (code,name,credit_code,type,address,contact,phone,remark,created_at,updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?)
            """, [c.code, c.name, c.creditCode, c.type, c.address, c.contact, c.phone, c.remark, now, now])
        c.id = id
        // 自动创建备案流程
        db.execute("INSERT INTO filing_process (company_id,status,created_at,updated_at) VALUES (?,?,?,?)",
                   [id, 0, now, now])
        return id
    }

    func update(_ c: Company) {
        db.execute("""
            UPDATE company SET name=?,credit_code=?,type=?,address=?,contact=?,phone=?,remark=?,updated_at=? WHERE id=?
            """, [c.name, c.creditCode, c.type, c.address, c.contact, c.phone, c.remark, TimeUtil.now(), c.id])
    }

    func delete(_ id: Int64) {
        let procs = db.query("SELECT id FROM filing_process WHERE company_id=?", [id])
        for p in procs {
            if let pid = p["id"] as? Int64 {
                db.execute("DELETE FROM modification_record WHERE process_id=?", [pid])
            }
        }
        db.execute("DELETE FROM filing_process WHERE company_id=?", [id])
        db.execute("DELETE FROM company WHERE id=?", [id])
        db.execute("DELETE FROM audit_log WHERE entity_id=?", [id])
    }

    func getById(_ id: Int64) -> Company? {
        let rows = db.query("SELECT * FROM company WHERE id=?", [id])
        guard let r = rows.first else { return nil }
        return map(r)
    }

    func list(_ query: String, limit: Int, offset: Int) -> [Company] {
        let sql = """
            SELECT c.*, IFNULL(fp.status,0) AS st FROM company c
            LEFT JOIN filing_process fp ON fp.company_id = c.id
            \(whereClause(query))
            ORDER BY c.updated_at DESC LIMIT ? OFFSET ?
            """
        let args = buildArgs(query) + [limit, offset]
        return db.query(sql, args).map { row in
            var c = map(row)
            c.status = (row["st"] as? Int64).map { Int($0) } ?? 0
            return c
        }
    }

    func count(_ query: String) -> Int {
        let sql = "SELECT COUNT(*) AS n FROM company \(whereClause(query))"
        let args: [Any?] = query.isEmpty ? [] : buildSearchArgs(query)
        let rows = db.query(sql, args)
        return Int((rows.first?["n"] as? Int64) ?? 0)
    }

    private func whereClause(_ q: String) -> String {
        q.isEmpty ? "" : "WHERE (name LIKE ? OR credit_code LIKE ? OR contact LIKE ? OR phone LIKE ?)"
    }

    private func buildSearchArgs(_ q: String) -> [Any?] {
        let like = "%" + q.trimmingCharacters(in: .whitespaces) + "%"
        return [like, like, like, like]
    }

    private func buildArgs(_ q: String) -> [Any?] {
        q.isEmpty ? [] : buildSearchArgs(q)
    }

    private func map(_ r: [String: Any]) -> Company {
        var c = Company()
        c.id = (r["id"] as? Int64) ?? 0
        c.code = (r["code"] as? String) ?? ""
        c.name = (r["name"] as? String) ?? ""
        c.creditCode = (r["credit_code"] as? String) ?? ""
        c.type = Int((r["type"] as? Int64) ?? 0)
        c.address = (r["address"] as? String) ?? ""
        c.contact = (r["contact"] as? String) ?? ""
        c.phone = (r["phone"] as? String) ?? ""
        c.remark = (r["remark"] as? String) ?? ""
        c.createdAt = (r["created_at"] as? Int64) ?? 0
        c.updatedAt = (r["updated_at"] as? Int64) ?? 0
        return c
    }
}
