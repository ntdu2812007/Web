#pragma once
#include <string>

class Staff {
public:
    std::string id;             // NV01 -> NV50
    std::string name;           // Nhân viên 01
    std::string email;          // nv01@system.com
    std::string password;       // staff01
    long long balance;          // Số dư ví COD (VNĐ)
    long long totalCommission;  // Tổng hoa hồng tích lũy
    int completedOrders;        // Số đơn hoàn thành

    Staff() : balance(0), totalCommission(0), completedOrders(0) {}

    Staff(std::string id, std::string name, std::string email, std::string password,
          long long balance, long long totalCommission, int completedOrders)
        : id(id), name(name), email(email), password(password),
          balance(balance), totalCommission(totalCommission), completedOrders(completedOrders) {}
};
