import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

final budgetServiceProvider = Provider((ref) => BudgetService(ref));

class BudgetService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BudgetService(this.ref);

  // Fungsi untuk mengatur atau memperbarui limit budget
  Future<void> setBudget({required String category, required double limitAmount}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception("User belum login!");

    // Cek apakah budget untuk kategori ini sudah ada
    final query = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Jika sudah ada, update limitnya
      await query.docs.first.reference.update({
        'limitAmount': limitAmount,
      });
    } else {
      // Jika belum ada, buat dokumen baru
      final docRef = _firestore.collection('budgets').doc();
      await docRef.set({
        'budgetId': docRef.id,
        'userId': userId, // ATURAN WAJIB
        'category': category,
        'limitAmount': limitAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}