import Foundation
import SQLite3

final class Database {
    static let shared = Database()
    private var db: OpaquePointer?

    private init() {
        open()
        createTables()
    }

    private func dbPath() -> String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return (dir as NSString).appendingPathComponent("filing.db")
    }

    func open() {
        if sqlite3_open(dbPath(), &db) != SQLITE_OK {
            print("DB open failed")
        }
    }

    func close() {
        if db != nil { sqlite3_close(db); db = nil }
    }

    func connection() -> OpaquePointer? { db }

    private func exec(_ sql: String) {
        var err: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let e = err { print("SQL error: \(String(cString: e))") }
            sqlite3_free(err)
        }
    }

    private func createTables() {
        exec("""
        CREATE TABLE IF NOT EXISTS company (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE, name TEXT, credit_code TEXT, type INTEGER,
            address TEXT, contact TEXT, phone TEXT, remark TEXT,
            created_at INTEGER, updated_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS filing_process (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER, status INTEGER,
            apply_time INTEGER, send_to_gacc_time INTEGER,
            created_at INTEGER, updated_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS modification_record (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            process_id INTEGER, type INTEGER, occur_time INTEGER,
            content TEXT, remark TEXT, created_at INTEGER
        );
        CREATE TABLE IF NOT EXISTS audit_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT, entity_id INTEGER, action TEXT,
            old_data TEXT, new_data TEXT, operator TEXT, created_at INTEGER
        );
        """)
    }

    func lastInsertId() -> Int64 { sqlite3_last_insert_rowid(db) }

    /// 执行写操作，返回 lastInsertId
    @discardableResult
    func execute(_ sql: String, _ args: [Any?] = []) -> Int64 {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            print("prepare failed: \(sql)"); return -1
        }
        bind(stmt, args)
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("step failed")
        }
        sqlite3_finalize(stmt)
        return lastInsertId()
    }

    func query(_ sql: String, _ args: [Any?] = []) -> [[String: Any]] {
        var stmt: OpaquePointer?
        var rows: [[String: Any]] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return rows }
        bind(stmt, args)
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let colCount = sqlite3_column_count(stmt)
            for i in 0..<colCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                let type = sqlite3_column_type(stmt, i)
                if type == SQLITE_INTEGER {
                    row[name] = Int64(sqlite3_column_int64(stmt, i))
                } else if type == SQLITE_TEXT {
                    if let ptr = sqlite3_column_text(stmt, i) {
                        row[name] = String(cString: ptr)
                    }
                } else if type == SQLITE_NULL {
                    row[name] = NSNull()
                }
            }
            rows.append(row)
        }
        sqlite3_finalize(stmt)
        return rows
    }

    private func bind(_ stmt: OpaquePointer?, _ args: [Any?]) {
        for (i, arg) in args.enumerated() {
            let idx = Int32(i + 1)
            if arg == nil || arg is NSNull {
                sqlite3_bind_null(stmt, idx)
            } else if let v = arg as? Int64 {
                sqlite3_bind_int64(stmt, idx, v)
            } else if let v = arg as? Int {
                sqlite3_bind_int64(stmt, idx, Int64(v))
            } else if let v = arg as? String {
                sqlite3_bind_text(stmt, idx, v, -1, nil)
            } else if let v = arg as? Double {
                sqlite3_bind_double(stmt, idx, v)
            }
        }
    }
}
