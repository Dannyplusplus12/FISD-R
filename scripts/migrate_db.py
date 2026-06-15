"""
Migrate data from attractive-analysis Postgres → FISD Postgres.
- Drops all existing tables in FISD DB
- Creates new Vietnamese-named schema
- Copies all rows preserving IDs, resets sequences at the end

Usage:
    SRC_DB=<source_url> DST_DB=<dest_url> python scripts/migrate_db.py
"""
import os
import sys
import psycopg2
from psycopg2.extras import execute_values

SRC = os.environ.get("SRC_DB")
DST = os.environ.get("DST_DB")

if not SRC or not DST:
    print("Error: set SRC_DB and DST_DB environment variables")
    sys.exit(1)

DDL = """
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE khu_vuc (
    id SERIAL PRIMARY KEY,
    ten VARCHAR
);

CREATE TABLE nhan_vien (
    id SERIAL PRIMARY KEY,
    ten VARCHAR,
    so_dien_thoai VARCHAR DEFAULT '',
    email VARCHAR DEFAULT '',
    dia_chi VARCHAR DEFAULT '',
    ghi_chu VARCHAR DEFAULT '',
    vai_tro VARCHAR DEFAULT 'orderer',
    ma_pin VARCHAR DEFAULT '',
    dang_hoat_dong INTEGER DEFAULT 1,
    thoi_gian_tao VARCHAR DEFAULT ''
);

CREATE TABLE san_pham (
    id SERIAL PRIMARY KEY,
    ma_hang VARCHAR DEFAULT '',
    ten VARCHAR,
    mo_ta VARCHAR DEFAULT '',
    duong_dan_anh VARCHAR DEFAULT ''
);

CREATE TABLE bien_the (
    id SERIAL PRIMARY KEY,
    ma_san_pham INTEGER REFERENCES san_pham(id),
    mau_sac VARCHAR DEFAULT '',
    kich_co VARCHAR DEFAULT '',
    don_gia INTEGER DEFAULT 0,
    ton_kho INTEGER DEFAULT 0
);

CREATE TABLE khach_hang (
    id SERIAL PRIMARY KEY,
    ten VARCHAR,
    so_dien_thoai VARCHAR DEFAULT '',
    no_hien_tai INTEGER DEFAULT 0,
    ma_khu_vuc INTEGER REFERENCES khu_vuc(id)
);

CREATE TABLE don_hang (
    id SERIAL PRIMARY KEY,
    ten_khach_hang VARCHAR DEFAULT 'Khách lẻ',
    ma_khach_hang INTEGER REFERENCES khach_hang(id),
    thoi_gian_tao VARCHAR DEFAULT '',
    dau_moc_tao BIGINT DEFAULT 0,
    tong_tien INTEGER DEFAULT 0,
    la_nhap INTEGER DEFAULT 0,
    trang_thai VARCHAR DEFAULT 'completed',
    ghi_chu_picker VARCHAR DEFAULT '',
    ma_nv_tao INTEGER REFERENCES nhan_vien(id),
    ma_picker INTEGER REFERENCES nhan_vien(id),
    thoi_gian_nhan VARCHAR DEFAULT '',
    ma_nv_giao INTEGER REFERENCES nhan_vien(id),
    thoi_gian_giao VARCHAR DEFAULT '',
    duong_dan_anh_giao VARCHAR DEFAULT '',
    id_file_telegram VARCHAR DEFAULT '',
    id_tin_telegram VARCHAR DEFAULT ''
);

CREATE TABLE lich_su_no (
    id SERIAL PRIMARY KEY,
    ma_khach_hang INTEGER REFERENCES khach_hang(id),
    ma_nv_thuc_hien INTEGER REFERENCES nhan_vien(id),
    so_tien_thay_doi INTEGER DEFAULT 0,
    du_no_sau INTEGER DEFAULT 0,
    ghi_chu VARCHAR DEFAULT '',
    thoi_gian VARCHAR DEFAULT '',
    dau_moc BIGINT DEFAULT 0
);

CREATE TABLE chi_tiet_don (
    id SERIAL PRIMARY KEY,
    ma_don_hang INTEGER REFERENCES don_hang(id),
    ten_san_pham VARCHAR DEFAULT '',
    ma_bien_the INTEGER REFERENCES bien_the(id),
    thong_tin_bien_the VARCHAR DEFAULT '',
    so_luong INTEGER DEFAULT 1,
    don_gia INTEGER DEFAULT 0
);
"""


def fetch_all(cur, table, cols):
    cur.execute(f"SELECT {', '.join(cols)} FROM {table} ORDER BY id")
    return cur.fetchall()


def insert_rows(cur, table, cols, rows):
    if not rows:
        return
    sql = f"INSERT INTO {table} ({', '.join(cols)}) VALUES %s"
    execute_values(cur, sql, rows)


def reset_seq(cur, table, id_col="id"):
    cur.execute(f"SELECT setval(pg_get_serial_sequence('{table}', '{id_col}'), COALESCE((SELECT MAX({id_col}) FROM {table}), 0) + 1, false)")


def safe_str(v):
    if v is None:
        return ""
    if isinstance(v, str):
        return v
    return str(v)


def main():
    print("Kết nối databases...")
    src = psycopg2.connect(SRC)
    dst = psycopg2.connect(DST)
    sc = src.cursor()
    dc = dst.cursor()

    print("Xây dựng schema mới trong FISD DB...")
    dc.execute(DDL)
    dst.commit()

    # ── khu_vuc ← areas ────────────────────────────────────────────────────────
    print("Migrate khu_vuc...")
    sc.execute("SELECT id, name FROM areas ORDER BY id")
    rows = [(r[0], safe_str(r[1])) for r in sc.fetchall()]
    insert_rows(dc, "khu_vuc", ["id", "ten"], rows)
    reset_seq(dc, "khu_vuc")
    print(f"  {len(rows)} khu vực")

    # ── nhan_vien ← employees ──────────────────────────────────────────────────
    print("Migrate nhan_vien...")
    sc.execute("SELECT id, name, phone, email, address, notes, role, pin, is_active, created_at FROM employees ORDER BY id")
    rows = []
    for r in sc.fetchall():
        rows.append((
            r[0],                  # id
            safe_str(r[1]),        # ten
            safe_str(r[2]),        # so_dien_thoai
            safe_str(r[3]),        # email
            safe_str(r[4]),        # dia_chi
            safe_str(r[5]),        # ghi_chu
            safe_str(r[6]) or "orderer",  # vai_tro
            safe_str(r[7]),        # ma_pin
            int(r[8] or 1),        # dang_hoat_dong
            safe_str(r[9]),        # thoi_gian_tao
        ))
    insert_rows(dc, "nhan_vien", ["id", "ten", "so_dien_thoai", "email", "dia_chi", "ghi_chu", "vai_tro", "ma_pin", "dang_hoat_dong", "thoi_gian_tao"], rows)
    reset_seq(dc, "nhan_vien")
    print(f"  {len(rows)} nhân viên")

    # ── san_pham ← products ────────────────────────────────────────────────────
    print("Migrate san_pham...")
    sc.execute("SELECT id, code, name, description, image_path FROM products ORDER BY id")
    rows = []
    for r in sc.fetchall():
        rows.append((
            r[0],
            safe_str(r[1]),  # ma_hang
            safe_str(r[2]),  # ten
            safe_str(r[3]),  # mo_ta
            safe_str(r[4]),  # duong_dan_anh
        ))
    insert_rows(dc, "san_pham", ["id", "ma_hang", "ten", "mo_ta", "duong_dan_anh"], rows)
    reset_seq(dc, "san_pham")
    print(f"  {len(rows)} sản phẩm")

    # ── bien_the ← variants ────────────────────────────────────────────────────
    print("Migrate bien_the...")
    sc.execute("SELECT id, product_id, color, size, price, stock FROM variants ORDER BY id")
    rows = []
    for r in sc.fetchall():
        rows.append((
            r[0],
            r[1],            # ma_san_pham
            safe_str(r[2]),  # mau_sac
            safe_str(r[3]),  # kich_co
            int(r[4] or 0),  # don_gia
            int(r[5] or 0),  # ton_kho
        ))
    insert_rows(dc, "bien_the", ["id", "ma_san_pham", "mau_sac", "kich_co", "don_gia", "ton_kho"], rows)
    reset_seq(dc, "bien_the")
    print(f"  {len(rows)} biến thể")

    # ── khach_hang ← customers ─────────────────────────────────────────────────
    print("Migrate khach_hang...")
    sc.execute("SELECT id, name, phone, debt, area_id FROM customers ORDER BY id")
    rows = []
    for r in sc.fetchall():
        rows.append((
            r[0],
            safe_str(r[1]),  # ten
            safe_str(r[2]),  # so_dien_thoai
            int(r[3] or 0),  # no_hien_tai
            r[4],            # ma_khu_vuc (nullable)
        ))
    insert_rows(dc, "khach_hang", ["id", "ten", "so_dien_thoai", "no_hien_tai", "ma_khu_vuc"], rows)
    reset_seq(dc, "khach_hang")
    print(f"  {len(rows)} khách hàng")

    # ── don_hang ← orders ─────────────────────────────────────────────────────
    print("Migrate don_hang...")
    sc.execute("""
        SELECT id, customer_name, customer_id, created_at, created_ts, total_amount,
               is_draft, status, picker_note, created_by_employee_id, assigned_picker_id,
               assigned_at, delivered_by_id, delivered_at, delivery_photo_path,
               telegram_file_id, telegram_message_id
        FROM orders ORDER BY id
    """)
    rows = []
    for r in sc.fetchall():
        thoi_gian_tao = ""
        v = r[3]
        if v is not None:
            thoi_gian_tao = v if isinstance(v, str) else v.strftime("%Y-%m-%d %H:%M")
        thoi_gian_giao = ""
        v = r[13]
        if v is not None:
            thoi_gian_giao = v if isinstance(v, str) else v.strftime("%Y-%m-%d %H:%M")
        thoi_gian_nhan = ""
        v = r[11]
        if v is not None:
            thoi_gian_nhan = v if isinstance(v, str) else v.strftime("%Y-%m-%d %H:%M")
        rows.append((
            r[0],                          # id
            safe_str(r[1]) or "Khách lẻ", # ten_khach_hang
            r[2],                          # ma_khach_hang
            thoi_gian_tao,                 # thoi_gian_tao
            int(r[4] or 0),               # dau_moc_tao
            int(r[5] or 0),               # tong_tien
            int(r[6] or 0),               # la_nhap
            safe_str(r[7]) or "completed", # trang_thai
            safe_str(r[8]),                # ghi_chu_picker
            r[9],                          # ma_nv_tao
            r[10],                         # ma_picker
            thoi_gian_nhan,                # thoi_gian_nhan
            r[12],                         # ma_nv_giao
            thoi_gian_giao,                # thoi_gian_giao
            safe_str(r[14]),               # duong_dan_anh_giao
            safe_str(r[15]),               # id_file_telegram
            safe_str(r[16]),               # id_tin_telegram
        ))
    insert_rows(dc, "don_hang", [
        "id", "ten_khach_hang", "ma_khach_hang", "thoi_gian_tao", "dau_moc_tao",
        "tong_tien", "la_nhap", "trang_thai", "ghi_chu_picker", "ma_nv_tao",
        "ma_picker", "thoi_gian_nhan", "ma_nv_giao", "thoi_gian_giao",
        "duong_dan_anh_giao", "id_file_telegram", "id_tin_telegram"
    ], rows)
    reset_seq(dc, "don_hang")
    print(f"  {len(rows)} đơn hàng")

    # ── lich_su_no ← debt_logs ────────────────────────────────────────────────
    print("Migrate lich_su_no...")
    sc.execute("""
        SELECT id, customer_id, actor_employee_id, change_amount, new_balance,
               note, created_at, created_ts
        FROM debt_logs ORDER BY id
    """)
    rows = []
    for r in sc.fetchall():
        thoi_gian = ""
        v = r[6]
        if v is not None:
            thoi_gian = v if isinstance(v, str) else v.strftime("%Y-%m-%d %H:%M")
        rows.append((
            r[0],
            r[1],               # ma_khach_hang
            r[2],               # ma_nv_thuc_hien
            int(r[3] or 0),     # so_tien_thay_doi
            int(r[4] or 0),     # du_no_sau
            safe_str(r[5]),     # ghi_chu
            thoi_gian,          # thoi_gian
            int(r[7] or 0),     # dau_moc
        ))
    insert_rows(dc, "lich_su_no", ["id", "ma_khach_hang", "ma_nv_thuc_hien", "so_tien_thay_doi", "du_no_sau", "ghi_chu", "thoi_gian", "dau_moc"], rows)
    reset_seq(dc, "lich_su_no")
    print(f"  {len(rows)} lịch sử nợ")

    # ── chi_tiet_don ← order_items ────────────────────────────────────────────
    print("Migrate chi_tiet_don...")
    sc.execute("SELECT id, order_id, product_name, variant_id, variant_info, quantity, price FROM order_items ORDER BY id")
    rows = []
    for r in sc.fetchall():
        rows.append((
            r[0],
            r[1],               # ma_don_hang
            safe_str(r[2]),     # ten_san_pham
            r[3],               # ma_bien_the
            safe_str(r[4]),     # thong_tin_bien_the
            int(r[5] or 1),     # so_luong
            int(r[6] or 0),     # don_gia
        ))
    insert_rows(dc, "chi_tiet_don", ["id", "ma_don_hang", "ten_san_pham", "ma_bien_the", "thong_tin_bien_the", "so_luong", "don_gia"], rows)
    reset_seq(dc, "chi_tiet_don")
    print(f"  {len(rows)} chi tiết đơn")

    dst.commit()
    src.close()
    dst.close()
    print("\nHoàn tất! Dữ liệu đã được migrate sang FISD DB.")


if __name__ == "__main__":
    main()
