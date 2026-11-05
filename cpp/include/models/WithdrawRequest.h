#pragma once
#include <string>

class WithdrawRequest {
public:
    std::string id;             // WD-501
    std::string staffId;        // NV01
    std::string staffName;      // Nhân viên 01
    std::string bankName;       // MB Bank
    std::string bankAccount;    // 198082200407
    std::string accountName;    // NGUYEN DUC HUY
    long long amount;           // Số tiền muốn rút
    std::string status;         // PENDING, APPROVED, REJECTED
    std::string createdAt;
    std::string processedAt;

    WithdrawRequest() : amount(0), status("PENDING") {}
};
