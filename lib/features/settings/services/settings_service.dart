import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

final settingsServiceProvider = Provider((ref) => SettingsService(ref));

class SettingsService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SettingsService(this.ref);

  // Fungsi Update Profil
  Future<void> updateProfile({required String name, required String currency}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception("User belum login!");

    await _firestore.collection('users').doc(userId).update({
      'name': name,
      'currency': currency,
    });
  }

  // Fungsi Reset Data (Menghapus semua transaksi dan budget milik user)
  Future<void> resetData() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception("User belum login!");

    final batch = _firestore.batch();

    // Hapus semua transaksi user ini
    final txDocs = await _firestore.collection('transactions').where('userId', isEqualTo: userId).get();
    for (var doc in txDocs.docs) {
      batch.delete(doc.reference);
    }

    // Hapus semua budget user ini
    final budgetDocs = await _firestore.collection('budgets').where('userId', isEqualTo: userId).get();
    for (var doc in budgetDocs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Fungsi Logout
  void logout() {
    // Hapus sesi user dari memori Riverpod
    ref.read(currentUserIdProvider.notifier).state = null;
  }
}