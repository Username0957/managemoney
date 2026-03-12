import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// ─── User Data ───────────────────────────────────────────────────────────────
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snap) => snap.data());
});

// ─── All Transactions Stream ──────────────────────────────────────────────────
final _allTransactionsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
});

// ─── Recent Transactions (5 terbaru) ─────────────────────────────────────────
final recentTransactionsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final all = ref.watch(_allTransactionsStreamProvider);
  return all.whenData((list) => list.take(5).toList());
});

// ─── Dashboard Summary ────────────────────────────────────────────────────────
class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  /// Pengeluaran dikelompokkan per kategori (hanya Expense)
  final Map<String, double> expenseByCategory;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expenseByCategory,
  });
}

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final allTxAsync = ref.watch(_allTransactionsStreamProvider);
  final userAsync = ref.watch(userDataProvider);

  return allTxAsync.whenData((transactions) {
    double income = 0;
    double expense = 0;
    final Map<String, double> byCat = {};

    for (final tx in transactions) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final type = tx['type'] as String? ?? '';
      final category = tx['category'] as String? ?? 'Other';

      if (type == 'Income') {
        income += amount;
      } else if (type == 'Expense') {
        expense += amount;
        byCat[category] = (byCat[category] ?? 0) + amount;
      }
    }

    // Saldo = initialBalance + semua income - semua expense
    final initialBalance = userAsync.whenOrNull(
          data: (u) => (u?['initialBalance'] as num?)?.toDouble() ?? 0.0,
        ) ??
        0.0;

    return DashboardSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: initialBalance + income - expense,
      expenseByCategory: byCat,
    );
  });
});
