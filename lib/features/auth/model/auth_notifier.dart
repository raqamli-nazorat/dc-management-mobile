import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/dio_client.dart';
import '../api/auth_repository.dart';
import '../../../entities/session/repository/session_repository.dart';
import '../../../entities/session/model/session.dart';

// Session state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Providers
final _sessionRepoProvider = Provider((ref) => SessionRepository());
final _dioProvider = Provider((ref) => DioClient.create());
final _authRepoProvider = Provider((ref) => AuthRepository(ref.read(_dioProvider)));

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(_authRepoProvider),
    ref.read(_sessionRepoProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final SessionRepository _sessionRepo;

  AuthNotifier(this._authRepo, this._sessionRepo) : super(const AuthInitial()) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final hasToken = await _sessionRepo.hasToken();
    if (hasToken) {
      // In a real app, validate token with /auth/me
      state = const AuthUnauthenticated(); // Force login until /me validated
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final result = await _authRepo.login(email: email, password: password);
      await _sessionRepo.saveToken(result.token);
      state = AuthAuthenticated(result.user);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    await _sessionRepo.clearToken();
    state = const AuthUnauthenticated();
  }

  String _parseError(Object e) {
    return 'Login yoki parol noto\'g\'ri';
  }
}
