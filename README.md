# BÁO CÁO BÀI TẬP LỚN: HỆ THỐNG QUẢN TRỊ ĐƠN HÀNG & AFFILIATE (OMS)
**Môn học:** Thương Mại Điện Tử  
**Hệ thống:** Order Management System (OMS) trung gian giữa Quản Trị Viên (Admin) và 50 Nhân Viên Vận Hành.

---

## 1. Cấu Trúc Thư Mục Chuẩn Hóa Frontend (Giai đoạn 1)

Dự án đã được phân tách và module hóa hoàn toàn theo cấu trúc chuẩn React & TypeScript:

```
web/
├── src/
│   ├── types/
│   │   └── index.ts                 # Định nghĩa TypeScript interface (User, Staff, Order, Transaction, WithdrawRequest)
│   ├── constants/
│   │   └── mockData.ts              # Dữ liệu 50 NV (NV01-NV50), sàn TMĐT, đơn mẫu, cấu hình ngân hàng
│   ├── utils/
│   │   └── storage.ts               # Helper format tiền tệ VNĐ và đồng bộ localStorage (chống mất khi F5)
│   ├── components/
│   │   ├── common/
│   │   │   ├── Header.tsx           # Thanh điều hướng trên cùng, hiển thị số dư, role badge
│   │   │   ├── Footer.tsx           # Chân trang bản quyền môn học
│   │   │   ├── Toast.tsx            # Thông báo nổi (thành công, lỗi)
│   │   │   └── LoginScreen.tsx      # Màn hình đăng nhập bảo mật (Không dùng 1-click)
│   │   ├── admin/
│   │   │   ├── AdminView.tsx        # Điều phối các tab và logic của Quản trị viên
│   │   │   ├── CreateOrderTab.tsx   # Tạo đơn hàng, nhập mã đơn DH-xxxxx, tính hoa hồng
│   │   │   ├── StaffListTab.tsx     # Bảng quản lý 50 nhân viên, tìm kiếm, ví COD
│   │   │   ├── WithdrawApprovalTab.tsx # Xét duyệt chi tiền hoặc từ chối hoàn ví
│   │   │   └── SystemAuditLogTab.tsx   # Nhật ký giao dịch toàn hệ thống thời gian thực
│   │   ├── staff/
│   │   │   ├── StaffView.tsx        # Điều phối các tab của Nhân viên
│   │   │   ├── StaffHomeTab.tsx     # Danh sách các sàn TMĐT kết nối
│   │   │   ├── StaffWalletTab.tsx   # Ví cá nhân, lịch sử rút tiền
│   │   │   ├── StaffPendingOrdersTab.tsx # Nhận đơn PENDING -> CONFIRMED -> cộng hoa hồng
│   │   │   └── StaffHistoryTab.tsx  # Nhật ký biến động số dư cá nhân
│   │   └── modals/
│   │       ├── AdjustBalanceModal.tsx   # Modal Admin cộng/trừ tiền thủ công có ghi chú
│   │       ├── ChangePasswordModal.tsx  # Modal Admin reset/đổi mật khẩu cho NV
│   │       ├── DepositModal.tsx         # Modal nạp tiền ứng quỹ COD (STK + Cú pháp sao chép nhanh)
│   │       └── WithdrawModal.tsx        # Modal gửi yêu cầu rút hoa hồng về ngân hàng cá nhân
│   ├── App.tsx                      # Root App kết nối State và LocalStorage
│   └── main.tsx                     # Entry point React DOM
├── package.json                     # Cấu hình dependency Vite + React + Tailwind
├── tsconfig.json                    # Cấu hình TypeScript compiler
├── index.html                       # Phiên bản Standalone chạy trực tiếp mọi lúc mọi nơi
├── Chay-Web.bat                     # Phím tắt click đúp là mở web trên trình duyệt
└── README.md                        # Tài liệu hướng dẫn và ôn thi vấn đáp
```

---

## 2. Các Cải Tiến Khớp 100% Theo Đề Bài

1. **Loại bỏ hoàn toàn nút 1-Click Login:** Tuân thủ quy định bảo mật: *"Nhân viên phải đăng nhập bằng đúng Mã NV/Email và Mật khẩu cá nhân (Tuyệt đối không sử dụng cơ chế đăng nhập nhanh 1-click để tránh rút trộm tiền)"*.
2. **Bổ sung ô nhập Mã Đơn Hàng tùy chọn (VD: `DH-10029`):** Có nút tạo mã tự động và kiểm tra chống trùng lặp mã đơn.
3. **Quy trình Duyệt Rút Tiền & Hoàn Tiền:** Admin bấm `[Duyệt]` thì trừ tiền hệ thống; bấm `[Từ chối]` thì hoàn tiền lại vào Ví của Nhân viên và ghi log đối soát.
4. **Tích hợp `localStorage`:** Khi tải lại trang (bấm `F5` hoặc reload trình duyệt), toàn bộ đơn hàng mới tạo, số dư đã cộng, mật khẩu đã đổi và lịch sử giao dịch **vẫn được giữ nguyên vẹn 100%**.
5. **Thông tin Ngân hàng Chuyển Khoản:** Hiển thị rõ ràng STK, Ngân hàng, Chủ tài khoản, kèm nút sao chép nhanh cú pháp chuẩn: `[Mã NV] NAP TIEN`.

---

## 3. Thông Tin Đăng Nhập Hệ Thống

* **Quản trị viên (Admin):**
  * Email / Tài khoản: `admin@system.com`
  * Mật khẩu: `admin123`
* **50 Nhân viên (NV01 -> NV50):**
  * Mã NV: `NV01` đến `NV50` (hoặc email: `nv01@system.com` -> `nv50@system.com`)
  * Mật khẩu tương ứng: `staff01` đến `staff50`
