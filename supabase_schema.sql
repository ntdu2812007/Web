-- ====================================================================
-- HỆ THỐNG QUẢN LÝ ĐƠN HÀNG & AFFILIATE OMS (SUPABASE POSTGRESQL SCHEMA)
-- Môn học: Thương Mại Điện Tử
-- Hướng dẫn: Dán toàn bộ file này vào Supabase -> SQL Editor -> Bấm RUN
-- ====================================================================

CREATE TABLE IF NOT EXISTS staff (
    id VARCHAR(10) PRIMARY KEY,              -- 'NV01' đến 'NV50'
    name VARCHAR(100) NOT NULL,              -- 'Nhân viên 01'
    email VARCHAR(100) UNIQUE NOT NULL,      -- 'nv01@system.com'
    password VARCHAR(100) NOT NULL,          -- Replace plaintext auth with Supabase Auth for production.
    role VARCHAR(20) NOT NULL DEFAULT 'STAFF',
    balance BIGINT DEFAULT 0,                -- Số dư ví COD (VNĐ)
    total_commission BIGINT DEFAULT 0,       -- Tổng hoa hồng tích lũy (VNĐ)
    completed_orders INT DEFAULT 0,          -- Số đơn đã hoàn thành
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE staff ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'STAFF';

CREATE OR REPLACE FUNCTION public.login_staff(p_account TEXT, p_password TEXT)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    email VARCHAR,
    role VARCHAR,
    balance BIGINT,
    total_commission BIGINT,
    completed_orders INT
)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT s.id, s.name, s.email, s.role, s.balance, s.total_commission, s.completed_orders
    FROM public.staff AS s
    WHERE (LOWER(s.email) = LOWER(BTRIM(p_account)) OR LOWER(s.id) = LOWER(BTRIM(p_account)))
      AND s.password = p_password
    LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.login_staff(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.login_staff(TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_list_staff(p_admin_account TEXT, p_admin_password TEXT)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    email VARCHAR,
    password VARCHAR,
    role VARCHAR,
    balance BIGINT,
    total_commission BIGINT,
    completed_orders INT
)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT s.id, s.name, s.email, s.password, s.role, s.balance, s.total_commission, s.completed_orders
    FROM public.staff AS s
    WHERE s.role = 'STAFF'
      AND EXISTS (
          SELECT 1
          FROM public.staff AS admin
          WHERE admin.role = 'ADMIN'
            AND (LOWER(admin.email) = LOWER(BTRIM(p_admin_account)) OR LOWER(admin.id) = LOWER(BTRIM(p_admin_account)))
            AND admin.password = p_admin_password
      )
    ORDER BY s.id;
$$;

REVOKE ALL ON FUNCTION public.admin_list_staff(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_staff(TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.staff_deposit(
    p_account TEXT,
    p_password TEXT,
    p_amount BIGINT,
    p_note TEXT
)
RETURNS TABLE (new_balance BIGINT, transaction_id VARCHAR)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    staff_record public.staff%ROWTYPE;
    new_transaction_id VARCHAR(50);
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Số tiền nạp phải lớn hơn 0.';
    END IF;

    SELECT s.* INTO staff_record
    FROM public.staff AS s
    WHERE s.role = 'STAFF'
      AND (LOWER(s.email) = LOWER(BTRIM(p_account)) OR LOWER(s.id) = LOWER(BTRIM(p_account)))
      AND s.password = p_password
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Thông tin đăng nhập không hợp lệ.';
    END IF;

    UPDATE public.staff AS s
    SET balance = s.balance + p_amount
    WHERE s.id = staff_record.id
    RETURNING s.balance INTO new_balance;

    new_transaction_id := 'TX-' || REPLACE(gen_random_uuid()::TEXT, '-', '');

    INSERT INTO public.transactions (id, user_id, user_name, type, amount, note, status, timestamp)
    VALUES (
        new_transaction_id,
        staff_record.id,
        staff_record.name,
        'DEPOSIT',
        p_amount,
        COALESCE(NULLIF(BTRIM(p_note), ''), 'Nạp tiền ứng quỹ COD'),
        'SUCCESS',
        NOW()
    );

    transaction_id := new_transaction_id;
    RETURN NEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.staff_deposit(TEXT, TEXT, BIGINT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.staff_deposit(TEXT, TEXT, BIGINT, TEXT) TO anon, authenticated;

DROP FUNCTION IF EXISTS public.increment_staff_balance(VARCHAR, BIGINT);

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
    id VARCHAR(50) PRIMARY KEY,              -- Mã giao dịch
    user_id VARCHAR(50) NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,               -- 'COMMISSION', 'DEPOSIT', 'WITHDRAW', 'ADJUSTMENT'
    amount BIGINT NOT NULL,                  -- Số tiền biến động (+/-)
    note TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'SUCCESS',
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.load_account_data(p_account TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    account_record public.staff%ROWTYPE;
    result JSONB;
BEGIN
    SELECT s.* INTO account_record
    FROM public.staff AS s
    WHERE (LOWER(s.email) = LOWER(BTRIM(p_account)) OR LOWER(s.id) = LOWER(BTRIM(p_account)))
      AND s.password = p_password;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Thông tin đăng nhập không hợp lệ.';
    END IF;

    SELECT jsonb_build_object(
        'orders', COALESCE((
            SELECT jsonb_agg(to_jsonb(o) ORDER BY o.created_at DESC)
            FROM public.orders AS o
            WHERE account_record.role = 'ADMIN' OR o.staff_id = account_record.id
        ), '[]'::JSONB),
        'transactions', COALESCE((
            SELECT jsonb_agg(to_jsonb(t) ORDER BY t.timestamp DESC)
            FROM public.transactions AS t
            WHERE account_record.role = 'ADMIN' OR t.user_id = account_record.id
        ), '[]'::JSONB),
        'withdraw_requests', COALESCE((
            SELECT jsonb_agg(to_jsonb(w) ORDER BY w.created_at DESC)
            FROM public.withdraw_requests AS w
            WHERE account_record.role = 'ADMIN' OR w.staff_id = account_record.id
        ), '[]'::JSONB)
    ) INTO result;

    RETURN result;
END;
$$;
REVOKE ALL ON FUNCTION public.load_account_data(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.load_account_data(TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_adjust_staff_balance(
    p_admin_account TEXT,
    p_admin_password TEXT,
    p_staff_id TEXT,
    p_delta BIGINT,
    p_note TEXT
)
RETURNS TABLE (new_balance BIGINT, transaction_id VARCHAR)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    staff_record public.staff%ROWTYPE;
    pending_amount BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff AS a
        WHERE a.role = 'ADMIN'
          AND (LOWER(a.email) = LOWER(BTRIM(p_admin_account)) OR LOWER(a.id) = LOWER(BTRIM(p_admin_account)))
          AND a.password = p_admin_password
    ) THEN
        RAISE EXCEPTION 'Thông tin quản trị viên không hợp lệ.';
    END IF;
    IF p_delta = 0 THEN
        RAISE EXCEPTION 'Số tiền điều chỉnh phải khác 0.';
    END IF;

    SELECT s.* INTO staff_record
    FROM public.staff AS s
    WHERE s.id = p_staff_id AND s.role = 'STAFF'
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy nhân viên.';
    END IF;
    SELECT COALESCE(SUM(w.amount), 0) INTO pending_amount
    FROM public.withdraw_requests AS w
    WHERE w.staff_id = staff_record.id AND w.status = 'PENDING';
    IF staff_record.balance + p_delta < pending_amount THEN
        RAISE EXCEPTION 'Không thể giảm số dư thấp hơn tổng yêu cầu rút đang chờ.';
    END IF;

    UPDATE public.staff AS s
    SET balance = s.balance + p_delta
    WHERE s.id = staff_record.id
    RETURNING s.balance INTO new_balance;

    transaction_id := 'TX-' || REPLACE(gen_random_uuid()::TEXT, '-', '');
    INSERT INTO public.transactions (id, user_id, user_name, type, amount, note, status)
    VALUES (
        transaction_id, staff_record.id, staff_record.name, 'ADJUSTMENT', p_delta,
        COALESCE(NULLIF(BTRIM(p_note), ''), 'Admin điều chỉnh số dư'), 'SUCCESS'
    );
    RETURN NEXT;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_adjust_staff_balance(TEXT, TEXT, TEXT, BIGINT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_adjust_staff_balance(TEXT, TEXT, TEXT, BIGINT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_staff_password(
    p_admin_account TEXT, p_admin_password TEXT, p_staff_id TEXT, p_new_password TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff AS a
        WHERE a.role = 'ADMIN'
          AND (LOWER(a.email) = LOWER(BTRIM(p_admin_account)) OR LOWER(a.id) = LOWER(BTRIM(p_admin_account)))
          AND a.password = p_admin_password
    ) THEN
        RAISE EXCEPTION 'Thông tin quản trị viên không hợp lệ.';
    END IF;
    IF NULLIF(BTRIM(p_new_password), '') IS NULL THEN
        RAISE EXCEPTION 'Mật khẩu mới không được để trống.';
    END IF;

    UPDATE public.staff AS s
    SET password = BTRIM(p_new_password)
    WHERE s.id = p_staff_id AND s.role = 'STAFF';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy nhân viên.';
    END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_set_staff_password(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_staff_password(TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_create_order(
    p_admin_account TEXT, p_admin_password TEXT, p_id TEXT, p_staff_id TEXT,
    p_product_name TEXT, p_platform TEXT, p_order_value BIGINT, p_cod_amount BIGINT,
    p_commission_rate NUMERIC, p_commission_amount BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff AS a
        WHERE a.role = 'ADMIN'
          AND (LOWER(a.email) = LOWER(BTRIM(p_admin_account)) OR LOWER(a.id) = LOWER(BTRIM(p_admin_account)))
          AND a.password = p_admin_password
    ) THEN
        RAISE EXCEPTION 'Thông tin quản trị viên không hợp lệ.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.staff AS s WHERE s.id = p_staff_id AND s.role = 'STAFF') THEN
        RAISE EXCEPTION 'Không tìm thấy nhân viên được phân công.';
    END IF;
    IF NULLIF(BTRIM(p_id), '') IS NULL OR NULLIF(BTRIM(p_product_name), '') IS NULL
       OR p_order_value <= 0 OR p_cod_amount < 0 OR p_commission_rate < 0 OR p_commission_amount < 0 THEN
        RAISE EXCEPTION 'Thông tin đơn hàng không hợp lệ.';
    END IF;

    INSERT INTO public.orders (
        id, staff_id, product_name, platform, order_value, cod_amount,
        commission_rate, commission_amount, status
    ) VALUES (
        BTRIM(p_id), p_staff_id, BTRIM(p_product_name), p_platform, p_order_value,
        p_cod_amount, p_commission_rate, p_commission_amount, 'PENDING'
    );
END;
$$;
REVOKE ALL ON FUNCTION public.admin_create_order(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BIGINT, BIGINT, NUMERIC, BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_order(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BIGINT, BIGINT, NUMERIC, BIGINT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.staff_confirm_order(p_account TEXT, p_password TEXT, p_order_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    staff_record public.staff%ROWTYPE;
    order_record public.orders%ROWTYPE;
    new_balance BIGINT;
BEGIN
    SELECT s.* INTO staff_record
    FROM public.staff AS s
    WHERE s.role = 'STAFF'
      AND (LOWER(s.email) = LOWER(BTRIM(p_account)) OR LOWER(s.id) = LOWER(BTRIM(p_account)))
      AND s.password = p_password
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Thông tin đăng nhập không hợp lệ.';
    END IF;

    SELECT o.* INTO order_record
    FROM public.orders AS o
    WHERE o.id = p_order_id AND o.staff_id = staff_record.id
    FOR UPDATE;
    IF NOT FOUND OR order_record.status <> 'PENDING' THEN
        RAISE EXCEPTION 'Đơn hàng không còn ở trạng thái chờ xác nhận.';
    END IF;

    UPDATE public.staff AS s
    SET balance = s.balance + order_record.commission_amount,
        total_commission = s.total_commission + order_record.commission_amount,
        completed_orders = s.completed_orders + 1
    WHERE s.id = staff_record.id
    RETURNING s.balance INTO new_balance;

    UPDATE public.orders AS o
    SET status = 'CONFIRMED', confirmed_at = NOW()
    WHERE o.id = order_record.id;

    INSERT INTO public.transactions (id, user_id, user_name, type, amount, note, status)
    VALUES (
        'TX-' || REPLACE(gen_random_uuid()::TEXT, '-', ''),
        staff_record.id, staff_record.name, 'COMMISSION', order_record.commission_amount,
        'Hoa hồng đơn hàng ' || order_record.id || ' (' || order_record.platform || ')', 'SUCCESS'
    );
    RETURN new_balance;
END;
$$;
REVOKE ALL ON FUNCTION public.staff_confirm_order(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.staff_confirm_order(TEXT, TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.staff_request_withdraw(
    p_account TEXT, p_password TEXT, p_id TEXT, p_amount BIGINT,
    p_bank_name TEXT, p_bank_account TEXT, p_account_name TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    staff_record public.staff%ROWTYPE;
    pending_amount BIGINT;
BEGIN
    SELECT s.* INTO staff_record
    FROM public.staff AS s
    WHERE s.role = 'STAFF'
      AND (LOWER(s.email) = LOWER(BTRIM(p_account)) OR LOWER(s.id) = LOWER(BTRIM(p_account)))
      AND s.password = p_password
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Thông tin đăng nhập không hợp lệ.';
    END IF;
    IF p_amount < 50000 OR NULLIF(BTRIM(p_id), '') IS NULL
       OR NULLIF(BTRIM(p_bank_name), '') IS NULL OR NULLIF(BTRIM(p_bank_account), '') IS NULL
       OR NULLIF(BTRIM(p_account_name), '') IS NULL THEN
        RAISE EXCEPTION 'Thông tin yêu cầu rút tiền không hợp lệ.';
    END IF;
    SELECT COALESCE(SUM(w.amount), 0) INTO pending_amount
    FROM public.withdraw_requests AS w
    WHERE w.staff_id = staff_record.id AND w.status = 'PENDING';
    IF staff_record.balance - pending_amount < p_amount THEN
        RAISE EXCEPTION 'Số dư ví không đủ để rút số tiền này.';
    END IF;

    INSERT INTO public.withdraw_requests (
        id, staff_id, staff_name, bank_name, bank_account, account_name, amount, status
    ) VALUES (
        BTRIM(p_id), staff_record.id, staff_record.name, BTRIM(p_bank_name),
        BTRIM(p_bank_account), BTRIM(p_account_name), p_amount, 'PENDING'
    );
END;
$$;
REVOKE ALL ON FUNCTION public.staff_request_withdraw(TEXT, TEXT, TEXT, BIGINT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.staff_request_withdraw(TEXT, TEXT, TEXT, BIGINT, TEXT, TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_process_withdraw(
    p_admin_account TEXT, p_admin_password TEXT, p_request_id TEXT, p_approve BOOLEAN
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    request_record public.withdraw_requests%ROWTYPE;
    new_balance BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff AS a
        WHERE a.role = 'ADMIN'
          AND (LOWER(a.email) = LOWER(BTRIM(p_admin_account)) OR LOWER(a.id) = LOWER(BTRIM(p_admin_account)))
          AND a.password = p_admin_password
    ) THEN
        RAISE EXCEPTION 'Thông tin quản trị viên không hợp lệ.';
    END IF;

    SELECT w.* INTO request_record
    FROM public.withdraw_requests AS w
    WHERE w.id = p_request_id
    FOR UPDATE;
    IF NOT FOUND OR request_record.status <> 'PENDING' THEN
        RAISE EXCEPTION 'Yêu cầu không còn ở trạng thái chờ xử lý.';
    END IF;

    IF p_approve THEN
        UPDATE public.staff AS s
        SET balance = s.balance - request_record.amount
        WHERE s.id = request_record.staff_id AND s.balance >= request_record.amount
        RETURNING s.balance INTO new_balance;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Số dư nhân viên không đủ để duyệt yêu cầu.';
        END IF;
    ELSE
        SELECT s.balance INTO new_balance
        FROM public.staff AS s
        WHERE s.id = request_record.staff_id;
    END IF;

    UPDATE public.withdraw_requests AS w
    SET status = CASE WHEN p_approve THEN 'APPROVED' ELSE 'REJECTED' END,
        processed_at = NOW()
    WHERE w.id = request_record.id;

    INSERT INTO public.transactions (id, user_id, user_name, type, amount, note, status)
    VALUES (
        'TX-' || REPLACE(gen_random_uuid()::TEXT, '-', ''),
        request_record.staff_id, request_record.staff_name,
        CASE WHEN p_approve THEN 'WITHDRAW' ELSE 'ADJUSTMENT' END,
        CASE WHEN p_approve THEN -request_record.amount ELSE 0 END,
        CASE WHEN p_approve THEN
            'Duyệt chi tiền về ' || request_record.bank_name || ' - ' || request_record.bank_account || ' (' || request_record.account_name || ')'
        ELSE 'Từ chối lệnh rút tiền ' || request_record.id || ' (Giữ nguyên số dư)' END,
        CASE WHEN p_approve THEN 'SUCCESS' ELSE 'REJECTED' END
    );
    RETURN new_balance;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_process_withdraw(TEXT, TEXT, TEXT, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_process_withdraw(TEXT, TEXT, TEXT, BOOLEAN) TO anon, authenticated;

-- Broadcast only a table-change signal; clients reload protected data through RPCs.
CREATE OR REPLACE FUNCTION public.broadcast_oms_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    changed_record JSONB;
BEGIN
    changed_record := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
    PERFORM realtime.send(
        jsonb_build_object(
            'table', TG_TABLE_NAME,
            'operation', TG_OP,
            'staff_id', COALESCE(changed_record->>'staff_id', changed_record->>'user_id')
        ),
        'data_changed',
        'oms-data-changes',
        FALSE
    );
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS oms_broadcast_staff_changes ON public.staff;
CREATE TRIGGER oms_broadcast_staff_changes
AFTER INSERT OR UPDATE OR DELETE ON public.staff
FOR EACH ROW EXECUTE FUNCTION public.broadcast_oms_change();

DROP TRIGGER IF EXISTS oms_broadcast_order_changes ON public.orders;
CREATE TRIGGER oms_broadcast_order_changes
AFTER INSERT OR UPDATE OR DELETE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.broadcast_oms_change();

DROP TRIGGER IF EXISTS oms_broadcast_withdrawal_changes ON public.withdraw_requests;
CREATE TRIGGER oms_broadcast_withdrawal_changes
AFTER INSERT OR UPDATE OR DELETE ON public.withdraw_requests
FOR EACH ROW EXECUTE FUNCTION public.broadcast_oms_change();

DROP TRIGGER IF EXISTS oms_broadcast_transaction_changes ON public.transactions;
CREATE TRIGGER oms_broadcast_transaction_changes
AFTER INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION public.broadcast_oms_change();

ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdraw_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Tạo tài khoản ban đầu nếu chưa tồn tại; không ghi đè tài khoản hiện có.
-- Dọn các bản ghi demo được tạo bởi các phiên bản schema cũ.
DELETE FROM orders WHERE id IN ('DH-10021', 'DH-10022', 'DH-10023');
DELETE FROM transactions WHERE id IN ('TX-1001', 'TX-1002');

DO $$
DECLARE
    i INT;
    pad_id VARCHAR(5);
BEGIN
    INSERT INTO staff (id, name, email, password, role, balance, total_commission, completed_orders)
    VALUES ('ADMIN', 'Quản trị viên', 'admin@system.com', 'admin123', 'ADMIN', 0, 0, 0)
    ON CONFLICT (id) DO NOTHING;

    FOR i IN 1..50 LOOP
        pad_id := LPAD(i::TEXT, 2, '0');
        INSERT INTO staff (id, name, email, password, role, balance, total_commission, completed_orders)
        VALUES (
            'NV' || pad_id,
            'Nhân viên ' || pad_id,
            'nv' || pad_id || '@system.com',
            'staff' || pad_id,
            'STAFF',
            0,
            0,
            0
        )
        ON CONFLICT (id) DO NOTHING;
    END LOOP;
END $$;
