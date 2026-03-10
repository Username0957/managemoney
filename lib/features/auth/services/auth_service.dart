import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

final authServiceProvider = Provider((ref) => AuthService(ref));

class AuthService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this.ref);

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password) // Plain text sesuai spesifikasi
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        // Simpan userId ke provider global
        ref.read(currentUserIdProvider.notifier).state = userData['userId'];
        return true;
      }
      return false; // Email atau password salah
    } catch (e) {
      throw Exception('Gagal melakukan login: $e');
    }
  }

  // Fungsi Sign Up
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String currency,
    required double initialBalance,
  }) async {
    try {
      // Cek apakah email sudah terdaftar
      final emailCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw Exception('Email sudah digunakan');
      }

      // Buat dokumen user baru
      final docRef = _firestore.collection('users').doc();
      
      await docRef.set({
        'userId': docRef.id,
        'name': name,
        'email': email,
        'password': password,
        'currency': currency,
        'initialBalance': initialBalance,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Simpan userId ke provider global dan otomatis login
      ref.read(currentUserIdProvider.notifier).state = docRef.id;
      return true;
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }
}
