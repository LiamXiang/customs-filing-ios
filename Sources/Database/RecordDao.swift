import Foundation

final class RecordDao {
    private let db = Database.shared

    func getProcess(companyId: Int64) -> FilingProcess? {
        let rows = db.query("SELECT * FROM filing_process WHERE company_id=?", [companyId])
        guard let r = rows.first else { return nil }
        var p = FilingProcess()
        p.id = (r["id"] as? Int64) ?? 0
        p.companyId = companyId
        p.status = Int((r["status"] as? Int64) ?? 0)
        p.applyTime = r["apply_time"] as? Int64
        p.sendToGaccTime = r["send_to_gacc_time"] as? Int64
        p.createdAt = (r["created_at"] as? Int64) ?? 0
        p.updatedAt = (r["updated_at"] as? Int64) ?? 0
        return p
    }

    func updateProcess(_ p: FilingProcess) {
        db.execute("""
            UPDATE filing_process SET status=?, apply_time=?, send_to_gacc_time=?, updated_at=? WHERE id=?
            """, [p.status, p.applyTime ?? NSNull(), p.sendToGaccTime ?? NSNull(), TimeUtil.now(), p.id])
    }

    func updateStatus(processId: Int64, status: Int) {
        db.execute("UPDATE filing_process SET status=?, updated_at=? WHERE id=?",
                   [status, TimeUtil.now(), processId])
    }

    func list(processId: Int64) -> [ModRecord] {
        db.query("SELECT * FROM modification_record WHERE process_id=? ORDER BY occur_time ASC, id ASC",
                 [processId]).map { r in
            var rec = ModRecord()
            rec.id = (r["id"] as? Int64) ?? 0
            rec.processId = processId
            rec.type = Int((r["type"] as? Int64) ?? 0)
            rec.occurTime = (r["occur_time"] as? Int64) ?? 0
            rec.content = (r["content"] as? String) ?? ""
            rec.remark = (r["remark"] as? String) ?? ""
            rec.createdAt = (r["created_at"] as? Int64) ?? 0
            return rec
        }
    }

    func insert(_ r: ModRecord) -> Int64 {
        db.execute("""
            INSERT INTO modification_record (process_id,type,occur_time,content,remark,created_at)
            VALUES (?,?,?,?,?,?)
            """, [r.processId, r.type, r.occurTime, r.content, r.remark, TimeUtil.now()])
    }

    func update(_ r: ModRecord) {
        db.execute("UPDATE modification_record SET occur_time=?,content=?,remark=? WHERE id=?",
                   [r.occurTime, r.content, r.remark, r.id])
    }

    func delete(_ id: Int64) {
        db.execute("DELETE FROM modification_record WHERE id=?", [id])
    }
}

final class AuditDao {
    private let db = Database.shared

    func log(companyId: Int64, entityType: String, entityId: Int64, action: String, old: String, new: String) {
        db.execute("""
            INSERT INTO audit_log (entity_type,entity_id,action,old_data,new_data,operator,created_at)
            VALUES (?,?,?,?,?,?,?)
            """, [entityType, entityId, action, old, new, "本机用户", TimeUtil.now()])
    }

    func list(companyId: Int64) -> [AuditLog] {
        db.query("SELECT * FROM audit_log WHERE entity_id=? ORDER BY created_at DESC", [companyId]).map { r in
            var log = AuditLog()
            log.id = (r["id"] as? Int64) ?? 0
            log.entityType = (r["entity_type"] as? String) ?? ""
            log.entityId = (r["entity_id"] as? Int64) ?? 0
            log.action = (r["action"] as? String) ?? ""
            log.oldValue = (r["old_data"] as? String) ?? ""
            log.newValue = (r["new_data"] as? String) ?? ""
            log.operatorName = (r["operator"] as? String) ?? "本机用户"
            log.createdAt = (r["created_at"] as? Int64) ?? 0
            return log
        }
    }
}
