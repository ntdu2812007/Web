-- ====================================================================
-- HỆ THỐNG QUẢN LÝ ĐƠN HÀNG & AFFILIATE OMS (SUPABASE POSTGRESQL SCHEMA)
-- Môn học: Thương Mại Điện Tử
-- Hướng dẫn: Dán toàn bộ file này vào Supabase -> SQL Editor -> Bấm RUN
-- ====================================================================

-- 1. BẢNG 50 NHÂN VIÊN (STAFF)
CREATE TABLE IF NOT EXISTS staff (
    id VARCHAR(10) PRIMARY KEY,              -- 'NV01' đến 'NV50'
    name VARCHAR(100) NOT NULL,              -- 'Nhân viên 01'
    email VARCHAR(100) UNIQUE NOT NULL,      -- 'nv01@system.com'
    password VARCHAR(100) NOT NULL,          -- 'staff01'
    balance BIGINT DEFAULT 0,                -- Số dư ví COD (VNĐ)
    total_commission BIGINT DEFAULT 0,       -- Tổng hoa hồng tích lũy (VNĐ)
    completed_orders INT DEFAULT 0,          -- Số đơn đã hoàn thành
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BẢNG ĐƠN HÀNG (ORDERS)
CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(50) PRIMARY KEY,              -- Mã đơn (VD: 'DH-10029')
    staff_id VARCHAR(10) REFERENCES staff(id) ON DELETE CASCADE,
    product_name VARCHAR(255) NOT NULL,
    platform VARCHAR(50) NOT NULL,           -- 'Shopee', 'Lazada', 'TikTok Shop', 'Tiki', 'Sendo'
    order_value BIGINT NOT NULL,             -- Giá trị đơn hàng (VNĐ)
    cod_amount BIGINT DEFAULT 0,             -- Tiền thu hộ COD (VNĐ)
    commission_rate NUMERIC(5, 2) NOT NULL,  -- % Hoa hồng
    commission_amount BIGINT NOT NULL,       -- Tiền hoa hồng = Giá trị * (% / 100)
    status VARCHAR(20) DEFAULT 'PENDING',    -- 'PENDING' hoặc 'CONFIRMED'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ
);

-- 3. BẢNG YÊU CẦU RÚT TIỀN (WITHDRAW_REQUESTS)
CREATE TABLE IF NOT EXISTS withdraw_requests (
    id VARCHAR(50) PRIMARY KEY,              -- Mã lệnh (VD: 'WD-501')
    staff_id VARCHAR(10) REFERENCES staff(id) ON DELETE CASCADE,
    staff_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    bank_account VARCHAR(50) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    amount BIGINT NOT NULL,                  -- Số tiền rút (VNĐ)
    status VARCHAR(20) DEFAULT 'PENDING',    -- 'PENDING', 'APPROVED', 'REJECTED'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- 4. BẢNG AUDIT LOG - LỊCH SỬ GIAO DỊCH (TRANSACTIONS)
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(50) PRIMARY KEY,              -- Mã giao dịch (VD: 'TX-1001')
    user_id VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,               -- 'COMMISSION', 'DEPOSIT', 'WITHDRAW', 'ADJUSTMENT'
    amount BIGINT NOT NULL,                  -- Số tiền biến động (+/-)
    note TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'SUCCESS',
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- BẬT TÍNH NĂNG REALTIME (ĐỒNG BỘ TỨC THÌ GIỮA CÁC MÁY - BỎ QUA NẾU ĐÃ BẬT)
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE staff;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE orders;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE withdraw_requests;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- TẮT RLS HOẶC CHO PHÉP PUBLIC ĐỌC/GHI ĐỂ DEMO THỰC HÀNH MÔN HỌC DỄ DÀNG
ALTER TABLE staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE withdraw_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;

-- ====================================================================
-- SEED DỮ LIỆU BAN ĐẦU: 50 NHÂN VIÊN (NV01 - NV50) VÀ ĐƠN MẪU
-- ====================================================================
DO $$
DECLARE
    i INT;
    pad_id VARCHAR(5);
BEGIN
    FOR i IN 1..50 LOOP
        pad_id := LPAD(i::TEXT, 2, '0');
        INSERT INTO staff (id, name, email, password, balance, total_commission, completed_orders)
        VALUES (
            'NV' || pad_id,
            'Nhân viên ' || pad_id,
            'nv' || pad_id || '@system.com',
            'staff' || pad_id,
            FLOOR(RANDOM() * 4000000 + 1000000)::BIGINT,
            FLOOR(RANDOM() * 1500000 + 200000)::BIGINT,
            FLOOR(RANDOM() * 15 + 2)::INT
        )
        ON CONFLICT (id) DO NOTHING;
    END LOOP;
END $$;

-- ĐƠN HÀNG MẪU BAN ĐẦU
INSERT INTO orders (id, staff_id, product_name, platform, order_value, cod_amount, commission_rate, commission_amount, status, created_at)
VALUES 
('DH-10021', 'NV01', 'Áo Nam Premium Cotton 100%', 'Shopee', 500000, 350000, 10, 50000, 'PENDING', NOW() - INTERVAL '2 hours'),
('DH-10022', 'NV01', 'Tai nghe Bluetooth Pro Max', 'Lazada', 1200000, 1200000, 8, 96000, 'CONFIRMED', NOW() - INTERVAL '1 day'),
('DH-10023', 'NV02', 'Bàn phím cơ Không Dây RGB', 'TikTok Shop', 850000, 850000, 12, 102000, 'PENDING', NOW() - INTERVAL '4 hours')
ON CONFLICT (id) DO NOTHING;

-- NHẬT KÝ MẪU
INSERT INTO transactions (id, user_id, user_name, type, amount, note, status, timestamp)
VALUES
('TX-1001', 'NV01', 'Nhân viên 01', 'COMMISSION', 96000, 'Hoa hồng đơn hàng DH-10022 (Lazada)', 'SUCCESS', NOW() - INTERVAL '1 day'),
('TX-1002', 'NV01', 'Nhân viên 01', 'DEPOSIT', 1000000, 'Nạp tiền ứng quỹ COD', 'SUCCESS', NOW() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;
