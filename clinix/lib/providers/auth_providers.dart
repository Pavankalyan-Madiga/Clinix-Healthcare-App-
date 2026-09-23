import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/model/staff_model.dart';
import '../features/auth/data/repositories/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final preferences = ref.watch(
    sharedPreferencesProvider,
  );

  return AuthRepository(preferences);
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, StaffModel?>(
  (ref) {
    final repository = ref.watch(
      authRepositoryProvider,
    );

    return AuthNotifier(repository);
  },
);

class AuthNotifier extends StateNotifier<StaffModel?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository)
      : super(_repository.currentStaff);

  bool get isLoggedIn => state != null;

  List<StaffModel> getStaffDirectory() {
    return _repository.getStaffDirectory();
  }

  Future<String?> login({
    required String staffId,
    required String password,
  }) async {
    try {
      final staff = await _repository.login(
        staffId: staffId,
        password: password,
      );

      state = staff;

      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to sign in. Please try again.';
    }
  }

  Future<void> logout() async {
    await _repository.logout();

    state = null;
  }
}