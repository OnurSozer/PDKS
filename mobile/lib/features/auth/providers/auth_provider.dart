import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// User profile data model
class UserProfile {
  final String id;
  final String? companyId;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? startDate;
  final bool isActive;

  UserProfile({
    required this.id,
    this.companyId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.startDate,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      companyId: json['company_id'] as String?,
      role: json['role'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      startDate: json['start_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isChef => role == 'chef';
  bool get isEmployee => role == 'employee';
  bool get isMobileUser => role == 'employee' || role == 'chef';
}

// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserProfile? profile;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserProfile? profile,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository)
      : super(AuthState(isLoading: _repository.currentSession != null)) {
    _init();
  }

  Future<void> _init() async {
    final session = _repository.currentSession;
    if (session != null) {
      await _loadProfile(session.user.id);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadProfile(response.user!.id);
        return state.isAuthenticated;
      }
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await _repository.getProfile(userId);
      if (data != null) {
        final profile = UserProfile.fromJson(data);
        state = AuthState(
          isAuthenticated: true,
          profile: profile,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Profile not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshProfile() async {
    final user = _repository.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final userId = state.profile?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      await _loadProfile(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.changePassword(newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
