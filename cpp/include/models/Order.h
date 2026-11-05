#pragma once
#include <string>

class Order {
public:
    std::string id;                 // DH-10029
    std::string staffId;            // NV01
    std::string productName;        // Áo Nam Premium
    std::string platform;           // Shopee, Lazada, TikTok Shop...
    long long orderValue;           // Giá trị đơn hàng (VNĐ)
    long long codAmount;            // Tiền thu hộ COD
    double commissionRate;          // % Hoa hồng (VD: 10%)
    long long commissionAmount;     // Tiền hoa hồng = Giá trị * (% / 100)
    std::string status;             // PENDING, CONFIRMED
    std::string createdAt;          // Thời gian tạo
    std::string confirmedAt;        // Thời gian xác nhận

    Order() : orderValue(0), codAmount(0), commissionRate(0), commissionAmount(0), status("PENDING") {}

    // Tính toán hoa hồng theo công thức đề bài
    static long long calculateCommission(long long value, double rate) {
        return static_cast<long long>(value * (rate / 100.0) + 0.5);
    }
};
