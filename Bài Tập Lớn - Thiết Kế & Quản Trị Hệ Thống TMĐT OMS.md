# ĐỀ BÀI BÀI TẬP LỚN & HƯỚNG DẪN THỰC HÀNH (CHI TIẾT)

## **Môn học:** Thương mại Điện tử&nbsp;

## I. TỔNG QUAN ĐỀ BÀI

&nbsp;

**Nhiệm vụ của sinh viên:** Xây dựng và vận hành một ứng dụng Web OMS đóng vai trò là trung gian quản lý giữa **Quản trị viên (Admin/Doanh nghiệp)** và **50 Nhân viên Vận hành/Affiliate**.

---

## II. CHI TIẾT CÁC PHÂN HỆ&nbsp;

## 1\. Phân hệ Quản trị viên (Admin Module)

#### A. Quản lý 50 Tài khoản Nhân viên & Phân quyền

- **Khởi tạo dữ liệu:** Hệ thống phải có sẵn danh sách 50 tài khoản Nhân viên (Mã NV từ `NV01` đến `NV50`).  
- **Bảo mật & Cấp quyền:**  
  - Mỗi nhân viên có Mật khẩu ban đầu riêng biệt.  
  - Admin có chức năng **Đổi/Reset Mật khẩu** cho bất kỳ nhân viên nào nếu phát sinh sự cố bảo mật.  
- **Quản lý Tài chính Nhân viên:**  
  - Xem danh sách 50 NV cùng các chỉ số: Số dư Ví COD, Tổng hoa hồng tích lũy, Số đơn đã hoàn thành.  
  - Chức năng **Nạp / Trừ tiền thủ công** vào Ví NV (kèm nhập Lý do/Ghi chú đối soát).

#### B. Quy trình Tạo Đơn hàng & Phân bổ Tỷ lệ Hoa hồng

Khi khởi tạo một đơn hàng mới cho Nhân viên, Admin phải nhập đầy đủ các trường dữ liệu sau:

1. **Mã đơn hàng:** Mã duy nhất (ví dụ: `DH-10029`).  
2. **Nhân viên thụ hưởng:** Chọn 1 trong 50 Nhân viên từ danh sách.  
3. **Sàn Thương mại Điện tử:** Shopee, Lazada, TikTok Shop, Tiki, Sendo...  
4. **Giá trị đơn hàng (VNĐ):** Tổng giá trị sản phẩm khách mua.  
5. **Số tiền COD (VNĐ):** Số tiền thu hộ khi giao hàng (để NV tính toán ứng quỹ).  
6. **Tỷ lệ Hoa hồng (%):** Mức % nhân viên nhận được trên giá trị đơn hàng. $$\text{Tiền Hoa hồng} = \text{Giá trị đơn hàng} \times \left( \frac{\text{Tỷ lệ Hoa hồng}}{100} \right)$$ *Ví dụ:* Đơn giá trị $2.000.000$ VNĐ, % Hoa hồng là $5\% \rightarrow$ Hoa hồng NV nhận: $100.000$ VNĐ.

#### C. Duyệt Yêu cầu Rút tiền & Nhật ký Hệ thống

- **Duyệt Rút tiền:** Tiếp nhận các đơn xin rút hoa hồng từ NV (gồm Tên Ngân hàng, STK, Tên tài khoản, Số tiền). Admin bấm **\[Duyệt\]** (Tiền trừ trực tiếp vào hệ thống) hoặc **\[Từ chối\]** (Hoàn tiền lại Ví NV).  
- **Audit Log (Lịch sử giao dịch toàn hệ thống):** Theo dõi toàn bộ biến động tiền tệ (Nạp, Rút, Nhận hoa hồng) của cả 50 NV theo thời gian thực.

---

### 2\. Phân hệ Nhân viên (Staff Module)

#### A. Đăng nhập & Xác thực Tài khoản

- Nhân viên phải đăng nhập bằng đúng Mã NV/Email và Mật khẩu cá nhân (Tuyệt đối không sử dụng cơ chế đăng nhập nhanh 1-click để tránh rút trộm tiền).

#### B. Quản lý Ví COD & Cổng Nạp/Rút tiền

- **Hiển thị thông tin Nạp tiền (Ứng quỹ COD):**  
  - Ngân hàng:  để stk 1 thành viên trong nhóm  
  - Số tài khoản:&nbsp;  
  - Chủ tài khoản:&nbsp;  
  - Cú pháp CK chuẩn: `[Mã NV] NAP TIEN` (Ví dụ: `NV01 NAP TIEN`).  
- **Gửi Yêu cầu Rút tiền:** Cho phép NV tạo lệnh rút tiền hoa hồng tích lũy về tài khoản ngân hàng cá nhân.

#### C. Xác nhận Đơn hàng & Tích lũy Hoa hồng

- Khi Admin giao đơn, đơn hàng sẽ nằm ở trạng thái **Chờ xác nhận (PENDING)** trong giao diện NV.  
- NV kiểm tra thông tin đơn hàng $\rightarrow$ Bấm **\[Xác nhận đơn hàng\]**.  
- **Hệ thống xử lý:**  
  1. Trạng thái đơn đổi thành **CONFIRMED**.  
  2. Số tiền hoa hồng tự động **cộng vào Số dư Ví** của NV.  
  3. Ghi nhận lịch sử giao dịch vào phần **Lịch sử cá nhân**.

---

## III. THUẬT NGỮ TMĐT & BỘ CÂU HỎI THI BẢO VỆ (ORAL EXAM)

Giảng viên sẽ đặt các câu hỏi sau trong buổi bảo vệ Bài tập lớn để kiểm tra độ hiểu sâu của sinh viên:

---

&nbsp;