import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider ini menyimpan ID user yang sedang login.
// Nilai default-nya null (artinya belum login).
final currentUserIdProvider = StateProvider<String?>((ref) => null);