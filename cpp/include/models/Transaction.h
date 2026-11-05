#pragma once
#include <string>

class Transaction {
public:
    std::string id;             // TX-1001
    std::string userId;         // NV01
    std::string userName;       // Nhân viên 01
    std::string type;           // COMMISSION, DEPOSIT, WITHDRAW, ADJUSTMENT
    long long amount;           // Số tiền (+/-)
    std::string note;           // Ghi chú đối soát
    std::string status;         // SUCCESS, REJECTED
    std::string timestamp;      // Thời gian

    Transaction() : amount(0), status("SUCCESS") {}

    Transaction(std::string id, std::string userId, std::string userName,
                std::string type, long long amount, std::string note,
                std::string status, std::string timestamp)
        : id(id), userId(userId), userName(userName), type(type),
          amount(amount), note(note), status(status), timestamp(timestamp) {}
};
