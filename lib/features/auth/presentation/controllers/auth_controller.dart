import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';

final authStateProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
