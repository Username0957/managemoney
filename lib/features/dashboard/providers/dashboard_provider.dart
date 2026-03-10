import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// Provider untuk mengambil data User yang sedang login
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data());
});

// Provider untuk mengambil 5 transaksi terakhir milik user tersebut
final recentTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId) // ATURAN WAJIB: Filter by userId
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs.map((doc) => doc.data()).toList();
        
        // Sorting lokal berdasarkan waktu pembuatan (terbaru di atas)
        docs.sort((a, b) {
          final timeA = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final timeB = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return timeB.compareTo(timeA);
        });
        
        // Ambil maksimal 5 transaksi untuk di dashboard
        return docs.take(5).toList();
      });
});