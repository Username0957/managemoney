import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau aliran data dari Firestore secara real-time
    final userAsync = ref.watch(userDataProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh logic if needed
            ref.invalidate(userDataProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HEADER & BALANCE CARD ---
                userAsync.when(
                  data: (userData) {
                    final name = userData?['name'] ?? 'User';
                    final balance = userData?['initialBalance'] ?? 0.0;
                    final currency = userData?['currency'] ?? 'USD';

                    return _buildBalanceCard(name, balance, currency);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading user data: $e'),
                ),
                
                const SizedBox(height: 24),

                // --- 2. SPENDING OVERVIEW (Placeholder Visual) ---
                const Text(
                  "Spending Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSpendingOverviewCard(),

                const SizedBox(height: 24),

                // --- 3. RECENT TRANSACTIONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent transactions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // Nanti diarahkan ke tab TransactionsScreen
                      },
                      child: const Text(
                        "See All >",
                        style: TextStyle(color: AppTheme.accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No transactions yet. Add one!"),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _buildTransactionTile(tx);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading transactions: $e'),
                ),
                
                const SizedBox(height: 80), // Padding bawah agar tidak tertutup FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Komponen Kartu Saldo Utama (Hijau)
  Widget _buildBalanceCard(String name, double balance, String currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $name",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Total Balance",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "$currency ${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Row Income dan Expense
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIncomeExpenseItem(Icons.arrow_downward, "Income", "\$0", AppTheme.primaryColor),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildIncomeExpenseItem(Icons.arrow_upward, "Expense", "\$0", AppTheme.errorColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseItem(IconData icon, String title, String amount, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  // Komponen Spending Overview
  Widget _buildSpendingOverviewCard() {
    return CardData(
      child: Row(
        children: [
          // Dummy Circular Chart Visual
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Dummy data category
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Transport"),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  // Komponen Item Transaksi
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isExpense = tx['type'] == 'Expense';
    final amountColor = isExpense ? AppTheme.errorColor : AppTheme.primaryColor;
    final sign = isExpense ? "-" : "+";

    return CardData(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          // Nanti ikon bisa disesuaikan dengan 'category' dari Firestore
          child: const Icon(Icons.directions_car_outlined, color: Colors.black54),
        ),
        title: Text(tx['category'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(tx['date'] ?? 'No Date', style: const TextStyle(fontSize: 12)),
        trailing: Text(
          "$sign\$${tx['amount']?.toString() ?? '0'}",
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

// Widget Bantuan agar bentuk Card konsisten (Radius 18 sesuai JSON)
class CardData extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const CardData({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18), // Sesuai spesifikasi
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Soft shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}