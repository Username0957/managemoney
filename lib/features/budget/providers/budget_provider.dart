import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// Provider untuk mengambil semua limit budget user
final budgetsProvider = StreamProvider<Map<String, double>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('budgets')
      .where('userId', isEqualTo: userId)
      // TIDAK menggunakan .orderBy() untuk menghindari error index
      .snapshots()
      .map((snapshot) {
    final Map<String, double> budgetMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      budgetMap[data['category'] as String] =
          (data['limitAmount'] as num?)?.toDouble() ?? 0.0;
    }
    return budgetMap;
  });
});

// Provider untuk menghitung total pengeluaran PER KATEGORI
final expensesByCategoryProvider = StreamProvider<Map<String, double>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value({});

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'Expense')
      // TIDAK menggunakan .orderBy() untuk menghindari error index
      .snapshots()
      .map((snapshot) {
    final Map<String, double> expenseMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'Other';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      expenseMap[category] = (expenseMap[category] ?? 0) + amount;
    }
    return expenseMap;
  });
});
