#pragma once
#include <vector>
#include <string>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <ctime>
#include "../models/Staff.h"
#include "../models/Order.h"
#include "../models/Transaction.h"
#include "../models/WithdrawRequest.h"

class OMSController {
private:
    std::vector<Staff> staffList;
    std::vector<Order> orders;
    std::vector<Transaction> transactions;
    std::vector<WithdrawRequest> withdrawRequests;

    std::string getCurrentTime() {
        std::time_t now = std::time(nullptr);
        std::tm ltm;
#if defined(_WIN32) || defined(_WIN64)
        localtime_s(&ltm, &now);
#else
        localtime_r(&now, &ltm);
#endif
        std::ostringstream oss;
        oss << std::put_time(&ltm, "%d/%m/%Y, %H:%M:%S");
        return oss.str();
    }

public:
    OMSController() {
        init50Staff();
    }

    // 1. Khởi tạo danh sách 50 nhân viên theo đúng đề bài
    void init50Staff() {
        staffList.clear();
        for (int i = 1; i <= 50; ++i) {
            std::ostringstream idStream, emailStream, passStream;
            idStream << "NV" << std::setw(2) << std::setfill('0') << i;
            emailStream << "nv" << std::setw(2) << std::setfill('0') << i << "@system.com";
            passStream << "staff" << std::setw(2) << std::setfill('0') << i;

            std::string id = idStream.str();
            std::string name = "Nhân viên " + (i < 10 ? "0" + std::to_string(i) : std::to_string(i));
            std::string email = emailStream.str();
            std::string pass = passStream.str();

            long long initialBalance = 1000000 + (i * 50000);
            long long initialCommission = 200000 + (i * 20000);
            int completed = 2 + (i % 5);

            staffList.emplace_back(id, name, email, pass, initialBalance, initialCommission, completed);
        }

        // Tạo sẵn đơn hàng mẫu
        Order o1;
        o1.id = "DH-10021";
        o1.staffId = "NV01";
        o1.productName = "Áo Nam Premium Cotton 100%";
        o1.platform = "Shopee";
        o1.orderValue = 500000;
        o1.codAmount = 350000;
        o1.commissionRate = 10.0;
        o1.commissionAmount = 50000;
        o1.status = "PENDING";
        o1.createdAt = getCurrentTime();
        orders.push_back(o1);

        Order o2;
        o2.id = "DH-10022";
        o2.staffId = "NV01";
        o2.productName = "Tai nghe Bluetooth Pro Max";
        o2.platform = "Lazada";
        o2.orderValue = 1200000;
        o2.codAmount = 1200000;
        o2.commissionRate = 8.0;
        o2.commissionAmount = 96000;
        o2.status = "CONFIRMED";
        o2.createdAt = getCurrentTime();
        o2.confirmedAt = getCurrentTime();
        orders.push_back(o2);
    }

    // 2. Xác thực đăng nhập (Admin & 50 Nhân viên)
    bool authenticateAdmin(const std::string& email, const std::string& password) {
        return (email == "admin@system.com" && password == "admin123");
    }

    Staff* authenticateStaff(const std::string& account, const std::string& password) {
        for (auto& s : staffList) {
            if ((s.id == account || s.email == account) && s.password == password) {
                return &s;
            }
        }
        return nullptr;
    }

    // 3. Quản lý Đơn hàng: Tạo đơn & Tính hoa hồng
    bool createOrder(Order& newOrder, std::string& errorMsg) {
        // Kiểm tra trùng mã đơn
        for (const auto& ord : orders) {
            if (ord.id == newOrder.id) {
                errorMsg = "Mã đơn hàng " + newOrder.id + " đã tồn tại!";
                return false;
            }
        }

        // Tính tiền hoa hồng theo công thức
        newOrder.commissionAmount = Order::calculateCommission(newOrder.orderValue, newOrder.commissionRate);
        newOrder.status = "PENDING";
        newOrder.createdAt = getCurrentTime();

        orders.insert(orders.begin(), newOrder);
        return true;
    }

    // 4. Nhân viên Xác nhận đơn hàng -> Tự động cộng hoa hồng vào Ví
    bool confirmOrder(const std::string& orderId, const std::string& staffId) {
        for (auto& ord : orders) {
            if (ord.id == orderId && ord.staffId == staffId && ord.status == "PENDING") {
                ord.status = "CONFIRMED";
                ord.confirmedAt = getCurrentTime();

                // Cộng tiền vào ví nhân viên
                Staff* s = getStaffById(staffId);
                if (s) {
                    s->balance += ord.commissionAmount;
                    s->totalCommission += ord.commissionAmount;
                    s->completedOrders += 1;

                    // Ghi nhận Audit Log
                    Transaction tx;
                    tx.id = "TX-" + std::to_string(rand() % 9000 + 1000);
                    tx.userId = s->id;
                    tx.userName = s->name;
                    tx.type = "COMMISSION";
                    tx.amount = ord.commissionAmount;
                    tx.note = "Nhận hoa hồng đơn hàng " + ord.id + " (" + ord.platform + ")";
                    tx.status = "SUCCESS";
                    tx.timestamp = getCurrentTime();
                    transactions.insert(transactions.begin(), tx);
                }
                return true;
            }
        }
        return false;
    }

    // 5. Quản lý Ví & Nạp / Rút tiền
    bool requestWithdraw(const std::string& staffId, long long amount,
                         const std::string& bankName, const std::string& bankAccount,
                         const std::string& accountName, std::string& errorMsg) {
        Staff* s = getStaffById(staffId);
        if (!s) {
            errorMsg = "Không tìm thấy nhân viên!";
            return false;
        }
        if (amount <= 0 || amount > s->balance) {
            errorMsg = "Số dư ví không đủ để rút!";
            return false;
        }

        WithdrawRequest req;
        req.id = "WD-" + std::to_string(rand() % 900 + 100);
        req.staffId = s->id;
        req.staffName = s->name;
        req.bankName = bankName;
        req.bankAccount = bankAccount;
        req.accountName = accountName;
        req.amount = amount;
        req.status = "PENDING";
        req.createdAt = getCurrentTime();

        withdrawRequests.insert(withdrawRequests.begin(), req);
        return true;
    }

    // 6. Admin Duyệt rút tiền (Trừ tiền vào hệ thống)
    bool approveWithdraw(const std::string& requestId) {
        for (auto& req : withdrawRequests) {
            if (req.id == requestId && req.status == "PENDING") {
                Staff* s = getStaffById(req.staffId);
                if (s) {
                    s->balance = std::max(0LL, s->balance - req.amount);
                    req.status = "APPROVED";
                    req.processedAt = getCurrentTime();

                    Transaction tx;
                    tx.id = "TX-" + std::to_string(rand() % 9000 + 1000);
                    tx.userId = s->id;
                    tx.userName = s->name;
                    tx.type = "WITHDRAW";
                    tx.amount = -req.amount;
                    tx.note = "Duyệt chi hoa hồng về " + req.bankName + " (" + req.bankAccount + ")";
                    tx.status = "SUCCESS";
                    tx.timestamp = getCurrentTime();
                    transactions.insert(transactions.begin(), tx);
                    return true;
                }
            }
        }
        return false;
    }

    // 7. Admin Từ chối rút tiền (Hoàn tiền lại ví nhân viên theo đề bài)
    bool rejectWithdraw(const std::string& requestId) {
        for (auto& req : withdrawRequests) {
            if (req.id == requestId && req.status == "PENDING") {
                req.status = "REJECTED";
                req.processedAt = getCurrentTime();

                Transaction tx;
                tx.id = "TX-" + std::to_string(rand() % 9000 + 1000);
                tx.userId = req.staffId;
                tx.userName = req.staffName;
                tx.type = "ADJUSTMENT";
                tx.amount = 0;
                tx.note = "Từ chối lệnh rút tiền " + req.id + " (Giữ nguyên ví NV)";
                tx.status = "REJECTED";
                tx.timestamp = getCurrentTime();
                transactions.insert(transactions.begin(), tx);
                return true;
            }
        }
        return false;
    }

    // 8. Admin Điều chỉnh số dư thủ công
    void adjustBalance(const std::string& staffId, long long amount, bool isAdd, const std::string& reason) {
        Staff* s = getStaffById(staffId);
        if (!s) return;

        long long delta = isAdd ? amount : -amount;
        s->balance = std::max(0LL, s->balance + delta);

        Transaction tx;
        tx.id = "TX-" + std::to_string(rand() % 9000 + 1000);
        tx.userId = s->id;
        tx.userName = s->name;
        tx.type = "ADJUSTMENT";
        tx.amount = delta;
        tx.note = reason.empty() ? (isAdd ? "Admin cộng tiền thủ công" : "Admin trừ tiền thủ công") : reason;
        tx.status = "SUCCESS";
        tx.timestamp = getCurrentTime();
        transactions.insert(transactions.begin(), tx);
    }

    // 9. Admin Đổi / Reset Mật khẩu NV
    bool changeStaffPassword(const std::string& staffId, const std::string& newPassword) {
        Staff* s = getStaffById(staffId);
        if (s) {
            s->password = newPassword;
            return true;
        }
        return false;
    }

    Staff* getStaffById(const std::string& id) {
        for (auto& s : staffList) {
            if (s.id == id) return &s;
        }
        return nullptr;
    }

    const std::vector<Staff>& getStaffList() const { return staffList; }
    const std::vector<Order>& getOrders() const { return orders; }
    const std::vector<Transaction>& getTransactions() const { return transactions; }
    const std::vector<WithdrawRequest>& getWithdrawRequests() const { return withdrawRequests; }
};
