import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// State untuk menyimpan filter yang sedang aktif
final transactionFilterProvider = StateProvider<String>((ref) => 'All');

// Provider untuk mengambil dan memfilter semua transaksi
final allTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final filter = ref.watch(transactionFilterProvider);

  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId) // ATURAN WAJIB
      .snapshots()
      .map((snapshot) {
        var docs = snapshot.docs.map((doc) => doc.data()).toList();

        // 1. Sort lokal berdasarkan waktu pembuatan (terbaru di atas)
        docs.sort((a, b) {
          final timeA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final timeB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return timeB.compareTo(timeA); // Descending
        });

        // 2. Terapkan filter jika bukan 'All'
        if (filter != 'All') {
          docs = docs.where((doc) => doc['type'] == filter).toList();
        }

        return docs;
      });
});