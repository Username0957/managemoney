import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

final transactionServiceProvider = Provider((ref) => TransactionService(ref));

class TransactionService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionService(this.ref);

  Future<void> addTransaction({
    required String type, // 'Expense' atau 'Income'
    required double amount,
    required String category,
    required DateTime date,
    required String note,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception("User belum login!");

    // Gunakan batch agar penyimpanan transaksi dan update saldo terjadi bersamaan
    final batch = _firestore.batch();

    // 1. Buat referensi dokumen transaksi baru
    final txRef = _firestore.collection('transactions').doc();
    batch.set(txRef, {
      'transactionId': txRef.id,
      'userId': userId, // ATURAN WAJIB
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String().split('T')[0], // Simpan format YYYY-MM-DD
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update saldo di dokumen User
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    
    if (userDoc.exists) {
      double currentBalance = userDoc.data()?['initialBalance'] ?? 0.0;
      if (type == 'Expense') {
        currentBalance -= amount;
      } else {
        currentBalance += amount;
      }
      batch.update(userRef, {'initialBalance': currentBalance});
    }

    // Eksekusi semuanya
    await batch.commit();
  }
}