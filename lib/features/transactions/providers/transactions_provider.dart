import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// State filter aktif: 'All', 'Income', atau 'Expense'
final transactionFilterProvider = StateProvider<String>((ref) => 'All');

// Provider untuk mengambil dan memfilter semua transaksi
// PENTING: Tidak menggunakan .orderBy() + .where() bersamaan
// karena butuh Composite Index di Firestore.
// Sorting dilakukan secara lokal.
final allTransactionsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final filter = ref.watch(transactionFilterProvider);

  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    var docs = snapshot.docs.map((doc) => doc.data()).toList();

    // Sort lokal: terbaru di atas berdasarkan createdAt
    docs.sort((a, b) {
      final tA = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final tB = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return tB.compareTo(tA);
    });

    // Terapkan filter jika bukan 'All'
    if (filter != 'All') {
      docs = docs.where((doc) => doc['type'] == filter).toList();
    }

    return docs;
  });
});
