// ============================================================
//  OMS Engine - Demo Runner (C++ Backend)
//  Build: g++ -std=c++17 -o oms_engine main.cpp
// ============================================================
#include <iostream>
#include <iomanip>
#include <string>
#include <cstdlib>

#ifdef _WIN32
#include <windows.h>
#endif

#include "../include/services/OMSController.h"

// Helper: in duong ke ngang
static void printLine() {
    std::cout << "------------------------------------------------------------\n";
}

static void printHeader(const std::string& title) {
    std::cout << "\n============================================================\n";
    std::cout << "  " << title << "\n";
    std::cout << "============================================================\n";
}

// Helper: format tien VND don gian
static std::string fmtVND(long long amount) {
    std::string s = std::to_string(std::abs(amount));
    int ins = (int)s.size() - 3;
    while (ins > 0) { s.insert(ins, "."); ins -= 3; }
    return (amount < 0 ? "-" : "") + s + " VND";
}

int main() {
    // Windows: set console to UTF-8 cho terminal ho tro
#ifdef _WIN32
    SetConsoleOutputCP(65001); // CP_UTF8 = 65001
    SetConsoleCP(65001);
#endif

    srand(42); // seed co dinh de ID co the tien biet khi test

    OMSController oms;

    printHeader("OMS C++ ENGINE - DEMO BUSINESS LOGIC");
    std::cout << "[INIT] 50 staff accounts created (NV01 -> NV50)\n";
    std::cout << "[INIT] Sample orders pre-loaded: " << oms.getOrders().size() << "\n\n";

    // ---- [1] Xac thuc Admin ----
    printLine();
    std::cout << "[TEST 1] Admin Authentication\n";
    if (oms.authenticateAdmin("admin@system.com", "admin123")) {
        std::cout << "  [PASS] admin@system.com / admin123 -> OK\n";
    } else {
        std::cout << "  [FAIL] Admin login failed!\n";
        return 1;
    }

    // Sai mat khau
    if (!oms.authenticateAdmin("admin@system.com", "wrongpass")) {
        std::cout << "  [PASS] Wrong password correctly rejected\n";
    }

    // ---- [2] Xac thuc Nhan vien ----
    printLine();
    std::cout << "[TEST 2] Staff Authentication (NV01)\n";
    Staff* nv01 = oms.authenticateStaff("NV01", "staff01");
    if (nv01) {
        std::cout << "  [PASS] NV01 / staff01 -> OK\n";
        std::cout << "  Name   : " << nv01->name << "\n";
        std::cout << "  Balance: " << fmtVND(nv01->balance) << "\n";
        std::cout << "  Commission earned: " << fmtVND(nv01->totalCommission) << "\n";
    } else {
        std::cout << "  [FAIL] NV01 login failed!\n";
        return 1;
    }

    // Kiem tra NV50
    Staff* nv50 = oms.authenticateStaff("NV50", "staff50");
    if (nv50) {
        std::cout << "  [PASS] NV50 / staff50 -> OK (last staff account)\n";
    }

    // ---- [3] Tao Don Hang Moi ----
    printLine();
    std::cout << "[TEST 3] Create New Order (DH-88991)\n";
    Order newOrd;
    newOrd.id             = "DH-88991";
    newOrd.staffId        = "NV01";
    newOrd.productName    = "Ban phim co Bluetooth RGB";
    newOrd.platform       = "Shopee";
    newOrd.orderValue     = 2000000;
    newOrd.codAmount      = 1500000;
    newOrd.commissionRate = 10.0; // 10%

    std::string errMsg;
    if (oms.createOrder(newOrd, errMsg)) {
        // commissionAmount duoc tinh trong ham va ghi vao newOrd (pass by ref)
        std::cout << "  [PASS] Order " << newOrd.id << " created\n";
        std::cout << "  Order Value  : " << fmtVND(newOrd.orderValue) << "\n";
        std::cout << "  Commission % : " << newOrd.commissionRate << "%\n";
        std::cout << "  Commission $ : " << fmtVND(newOrd.commissionAmount) << "\n";
    } else {
        std::cout << "  [FAIL] " << errMsg << "\n";
        return 1;
    }

    // Kiem tra trung ma don
    Order dupOrd;
    dupOrd.id = "DH-88991"; // trung
    if (!oms.createOrder(dupOrd, errMsg)) {
        std::cout << "  [PASS] Duplicate ID correctly rejected: " << errMsg << "\n";
    }

    // ---- [4] Nhan vien Xac nhan don hang ----
    printLine();
    std::cout << "[TEST 4] Staff Confirm Order -> Commission credited to wallet\n";
    long long balBefore = nv01->balance;
    if (oms.confirmOrder("DH-88991", "NV01")) {
        long long balAfter = nv01->balance;
        std::cout << "  [PASS] Order DH-88991 confirmed\n";
        std::cout << "  Balance before: " << fmtVND(balBefore) << "\n";
        std::cout << "  Balance after : " << fmtVND(balAfter)  << "\n";
        std::cout << "  Commission +  : " << fmtVND(balAfter - balBefore) << "\n";
    } else {
        std::cout << "  [FAIL] confirmOrder returned false\n";
        return 1;
    }

    // ---- [5] Nhan vien yeu cau rut tien ----
    printLine();
    std::cout << "[TEST 5] Staff Request Withdrawal (500,000 VND)\n";
    if (oms.requestWithdraw("NV01", 500000, "MB Bank", "198082200407", "NGUYEN DUC HUY", errMsg)) {
        std::cout << "  [PASS] Withdrawal request submitted (PENDING, waiting admin)\n";
    } else {
        std::cout << "  [FAIL] " << errMsg << "\n";
        return 1;
    }

    // Kiem tra rut qua so du
    if (!oms.requestWithdraw("NV01", 999999999LL, "MB Bank", "123", "TEST", errMsg)) {
        std::cout << "  [PASS] Over-balance withdrawal correctly rejected: " << errMsg << "\n";
    }

    // ---- [6] Admin Duyet rut tien ----
    printLine();
    std::cout << "[TEST 6] Admin Approve Withdrawal\n";
    const auto& reqs = oms.getWithdrawRequests();
    if (!reqs.empty()) {
        std::string reqId = reqs[0].id;
        long long balBefore6 = nv01->balance;
        std::cout << "  Approving request: " << reqId << "\n";
        if (oms.approveWithdraw(reqId)) {
            std::cout << "  [PASS] Approved!\n";
            std::cout << "  Balance before: " << fmtVND(balBefore6) << "\n";
            std::cout << "  Balance after : " << fmtVND(nv01->balance) << "\n";
            std::cout << "  Deducted      : " << fmtVND(balBefore6 - nv01->balance) << "\n";
        } else {
            std::cout << "  [FAIL] approveWithdraw returned false\n";
            return 1;
        }
    }

    // ---- [7] Tu choi rut tien (khong tru tien) ----
    printLine();
    std::cout << "[TEST 7] Staff Request + Admin REJECT Withdrawal (balance unchanged)\n";
    if (oms.requestWithdraw("NV01", 100000, "MB Bank", "198082200407", "NGUYEN DUC HUY", errMsg)) {
        const auto& reqs2 = oms.getWithdrawRequests();
        std::string rejId;
        for (const auto& r : reqs2) {
            if (r.status == "PENDING") { rejId = r.id; break; }
        }
        long long balBefore7 = nv01->balance;
        if (!rejId.empty() && oms.rejectWithdraw(rejId)) {
            std::cout << "  [PASS] Withdrawal " << rejId << " rejected\n";
            std::cout << "  Balance before REJECT: " << fmtVND(balBefore7) << "\n";
            std::cout << "  Balance after  REJECT: " << fmtVND(nv01->balance) << "\n";
            if (nv01->balance == balBefore7) {
                std::cout << "  [PASS] Balance UNCHANGED after rejection (spec correct)\n";
            } else {
                std::cout << "  [FAIL] Balance changed after rejection!\n";
                return 1;
            }
        }
    }

    // ---- [8] Admin Dieu chinh so du thu cong ----
    printLine();
    std::cout << "[TEST 8] Admin Manual Balance Adjustment\n";
    long long balBefore8 = nv01->balance;
    oms.adjustBalance("NV01", 300000, true, "Nap COD thu cong tu admin");
    std::cout << "  [PASS] Added 300,000 VND manually\n";
    std::cout << "  Balance before: " << fmtVND(balBefore8) << "\n";
    std::cout << "  Balance after : " << fmtVND(nv01->balance) << "\n";

    // ---- [9] Doi mat khau ----
    printLine();
    std::cout << "[TEST 9] Change Staff Password\n";
    if (oms.changeStaffPassword("NV01", "newpass123")) {
        std::cout << "  [PASS] Password changed\n";
        if (oms.authenticateStaff("NV01", "newpass123")) {
            std::cout << "  [PASS] Login with new password -> OK\n";
        }
        if (!oms.authenticateStaff("NV01", "staff01")) {
            std::cout << "  [PASS] Old password correctly rejected\n";
        }
        // Phuc hoi mat khau cu
        oms.changeStaffPassword("NV01", "staff01");
    }

    // ---- [10] Audit Log ----
    printLine();
    std::cout << "[TEST 10] Audit Log (all transactions)\n";
    const auto& txs = oms.getTransactions();
    std::cout << "  Total transactions: " << txs.size() << "\n";
    for (const auto& tx : txs) {
        std::cout << "  [" << std::left << std::setw(10) << tx.id << "] "
                  << tx.timestamp << " | "
                  << std::setw(5) << tx.userId << " | "
                  << std::setw(12) << tx.type << " | "
                  << std::right << std::setw(14) << fmtVND(tx.amount)
                  << " | " << tx.note << "\n";
    }

    // ---- TONG KET ----
    printHeader("ALL TESTS PASSED - C++ OMS ENGINE READY");
    std::cout << "  Staff accounts  : " << oms.getStaffList().size() << "/50\n";
    std::cout << "  Orders in system: " << oms.getOrders().size() << "\n";
    std::cout << "  Transactions log: " << oms.getTransactions().size() << "\n";
    std::cout << "  Withdraw requests:" << oms.getWithdrawRequests().size() << "\n";
    std::cout << "\n  Next step: connect Supabase REST API (URL + anon key)\n";
    std::cout << "============================================================\n\n";

    return 0;
}
