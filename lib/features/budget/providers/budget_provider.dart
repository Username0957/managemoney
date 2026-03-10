import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// Provider untuk mengambil semua limit budget user
final budgetsProvider = StreamProvider<Map<String, double>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('budgets')
      .where('userId', isEqualTo: userId) // ATURAN WAJIB
      .snapshots()
      .map((snapshot) {
        final Map<String, double> budgetMap = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          budgetMap[data['category']] = (data['limitAmount'] ?? 0.0).toDouble();
        }
        return budgetMap;
      });
});

// Provider untuk menghitung total pengeluaran PER KATEGORI
final expensesByCategoryProvider = StreamProvider<Map<String, double>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: 'Expense') // Hanya hitung pengeluaran
      .snapshots()
      .map((snapshot) {
        final Map<String, double> expenseMap = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final category = data['category'] as String;
          final amount = (data['amount'] ?? 0.0).toDouble();
          
          if (expenseMap.containsKey(category)) {
            expenseMap[category] = expenseMap[category]! + amount;
          } else {
            expenseMap[category] = amount;
          }
        }
        return expenseMap;
      });
});