import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/notifications/reminder_notification_service.dart';
import 'package:mobile_ver/core/storage/local_storage.dart';
import 'package:mobile_ver/core/sync/sync_service.dart';

import '../models/user_model.dart';

class AuthActionResult {
  const AuthActionResult._({required this.isSuccess, required this.message});

  const AuthActionResult.success(String message)
    : this._(isSuccess: true, message: message);

  const AuthActionResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String message;
}

final userProvider = StateProvider<User?>((ref) => null);
final authLoadingProvider = StateProvider<bool>((ref) => true);

class AuthController extends StateNotifier<bool> {
  final Ref ref;

  AuthController(this.ref) : super(false) {
    _checkAuthStatus();
  }

  static final User _mockUser = User(
    id: 999,
    name: 'UI Tester',
    email: 'ui.tester@polylife.local',
    role: 'user',
    roleLabel: 'Pengguna',
    accountStatus: 'active',
    emailVerifiedAt: DateTime.now().toIso8601String(),
    affiliation: const UserAffiliation(
      type: 'university',
      name: 'PolyLife UI Lab',
      studentIdType: 'nim',
      studentIdNumber: '000000',
      status: 'verified',
    ),
    profile: const UserProfile(
      displayName: 'UI Tester',
      themePreference: 'system',
      timezone: 'Asia/Jakarta',
      locale: 'id',
    ),
  );

  Future<void> _checkAuthStatus() async {
    if (AppMode.uiOnly) {
      ref.read(userProvider.notifier).state = _mockUser;
      state = true;
      ref.read(authLoadingProvider.notifier).state = false;
      return;
    }

    final token = await LocalStorage.getToken();
    if (token != null) {
      try {
        final response = await ApiClient.get('/auth/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          final user = User.fromJson(Map<String, dynamic>.from(data));
          await LocalStorage.saveUser(user);
          ref.read(userProvider.notifier).state = user;
          state = true;
          await const SyncService().syncNow(user.id);
          await ReminderNotificationService.instance
              .scheduleUserRemindersFromDatabase(user.id);
        } else {
          await logout();
        }
      } on StateError {
        await LocalStorage.removeToken();
        ref.read(userProvider.notifier).state = null;
        state = false;
      } catch (_) {
        // Keep local session on transient network/startup failure.
        // Invalid token is still handled by non-200 response above.
        final cachedUser = await LocalStorage.getCachedUser();
        ref.read(userProvider.notifier).state = cachedUser;
        state = cachedUser != null;
      }
    } else {
      ref.read(userProvider.notifier).state = null;
      state = false;
    }
    ref.read(authLoadingProvider.notifier).state = false;
  }

  Future<String?> login(String email, String password) async {
    if (AppMode.uiOnly) {
      ref.read(userProvider.notifier).state = _mockUser;
      state = true;
      return null;
    }

    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
        'device_name': 'flutter-app',
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data =
            body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final token = data['access_token']?.toString() ?? '';
        final userData = data['user'];

        if (token.isEmpty || userData is! Map<String, dynamic>) {
          return 'Respons login tidak valid.';
        }

        final user = User.fromJson(userData);
        await LocalStorage.saveToken(token);
        await LocalStorage.saveUser(user);
        ref.read(userProvider.notifier).state = user;
        state = true;
        await const SyncService().syncNow(user.id);
        await ReminderNotificationService.instance
            .scheduleUserRemindersFromDatabase(user.id);
        return null; // success
      } else {
        return _messageFromResponse(response.body, 'Login gagal.');
      }
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return 'Network error occurred';
    }
  }

  Future<AuthActionResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success(
        'Akun berhasil dibuat. Silakan login kembali.',
      );
    }

    try {
      final response = await ApiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = _messageFromResponse(
        response.body,
        isSuccess ? 'Akun berhasil dibuat.' : 'Registrasi gagal.',
      );

      return isSuccess
          ? AuthActionResult.success(message)
          : AuthActionResult.failure(message);
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> requestPasswordReset(String email) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success(
        'Jika email terdaftar, link reset password akan dikirim.',
      );
    }

    try {
      final response = await ApiClient.post('/auth/forgot-password', {
        'email': email,
      });

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = _messageFromResponse(
        response.body,
        isSuccess
            ? 'Jika email terdaftar, link reset password akan dikirim.'
            : 'Permintaan reset password gagal.',
      );

      return isSuccess
          ? AuthActionResult.success(message)
          : AuthActionResult.failure(message);
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> refreshCurrentUser() async {
    if (AppMode.uiOnly) {
      ref.read(userProvider.notifier).state = _mockUser;
      state = true;
      return const AuthActionResult.success('Profil diperbarui.');
    }

    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final user = User.fromJson(Map<String, dynamic>.from(data));
        await LocalStorage.saveUser(user);
        ref.read(userProvider.notifier).state = user;
        state = true;
        await const SyncService().syncNow(user.id);
        return const AuthActionResult.success('Profil diperbarui.');
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
      }

      return AuthActionResult.failure(
        _messageFromResponse(response.body, 'Gagal memuat profil.'),
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure(
        'Profil lokal tetap dipakai. Koneksi belum tersedia.',
      );
    }
  }

  Future<AuthActionResult> updateProfile({
    required String displayName,
    required String bio,
    required String phone,
    required String dateOfBirth,
    required String gender,
    required String location,
    required String themePreference,
    required String timezone,
    required String locale,
  }) async {
    if (AppMode.uiOnly) {
      ref.read(userProvider.notifier).state = _mockUser;
      return const AuthActionResult.success('Profil berhasil diperbarui.');
    }

    try {
      final response = await ApiClient.patch('/profile', {
        'display_name': _nullableString(displayName),
        'bio': _nullableString(bio),
        'phone': _nullableString(phone),
        'date_of_birth': _nullableString(dateOfBirth),
        'gender': _nullableString(gender),
        'location': _nullableString(location),
        'theme_preference': themePreference,
        'timezone': _nullableString(timezone),
        'locale': _nullableString(locale),
      });

      return _persistUserActionResponse(
        response.body,
        response.statusCode,
        successFallback: 'Profil berhasil diperbarui.',
        failureFallback: 'Profil gagal diperbarui.',
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> uploadProfileAvatar(String filePath) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success('Foto profil berhasil diperbarui.');
    }

    try {
      final response = await ApiClient.postMultipart(
        '/profile/avatar',
        fileField: 'avatar',
        filePath: filePath,
      );

      return _persistUserActionResponse(
        response.body,
        response.statusCode,
        successFallback: 'Foto profil berhasil diperbarui.',
        failureFallback: 'Foto profil gagal diperbarui.',
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> deleteProfileAvatar() async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success('Foto profil berhasil dihapus.');
    }

    try {
      final response = await ApiClient.delete('/profile/avatar');

      return _persistUserActionResponse(
        response.body,
        response.statusCode,
        successFallback: 'Foto profil berhasil dihapus.',
        failureFallback: 'Foto profil gagal dihapus.',
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success(
        'Password berhasil diperbarui. Silakan login kembali.',
      );
    }

    final currentUser =
        ref.read(userProvider) ?? await LocalStorage.getCachedUser();

    try {
      final response = await ApiClient.patch('/profile/password', {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = _messageFromResponse(
        response.body,
        isSuccess
            ? 'Password berhasil diperbarui. Silakan login kembali.'
            : 'Password gagal diperbarui.',
      );

      if (!isSuccess) {
        return AuthActionResult.failure(message);
      }

      if (currentUser != null) {
        await ReminderNotificationService.instance.cancelAll();
        await AppDatabase.instance.clearUserData(currentUser.id);
      }
      await LocalStorage.removeToken();
      await LocalStorage.removeUser();
      ref.read(userProvider.notifier).state = null;
      state = false;

      return AuthActionResult.success(message);
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> submitAffiliationRequest({
    required String affiliationType,
    required String affiliationName,
    required String studentIdType,
    required String studentIdNumber,
  }) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success(
        'Pengajuan afiliasi berhasil dikirim.',
      );
    }

    try {
      final response = await ApiClient.post('/profile/affiliation-request', {
        'affiliation_type': affiliationType,
        'affiliation_name': affiliationName,
        'student_id_type': studentIdType,
        'student_id_number': studentIdNumber,
      });

      return _persistUserActionResponse(
        response.body,
        response.statusCode,
        successFallback: 'Pengajuan afiliasi berhasil dikirim.',
        failureFallback: 'Pengajuan afiliasi gagal dikirim.',
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> cancelAffiliationRequest() async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success('Pengajuan afiliasi dibatalkan.');
    }

    try {
      final response = await ApiClient.delete('/profile/affiliation-request');

      return _persistUserActionResponse(
        response.body,
        response.statusCode,
        successFallback: 'Pengajuan afiliasi dibatalkan.',
        failureFallback: 'Pengajuan afiliasi gagal dibatalkan.',
      );
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<AuthActionResult> deleteAccount({required String password}) async {
    if (AppMode.uiOnly) {
      return const AuthActionResult.success('Akun berhasil dihapus.');
    }

    final currentUser = ref.read(userProvider);

    try {
      final response = await ApiClient.deleteWithBody('/profile/account', {
        'password': password,
      });

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = _messageFromResponse(
        response.body,
        isSuccess ? 'Akun berhasil dihapus.' : 'Akun gagal dihapus.',
      );

      if (!isSuccess) {
        return AuthActionResult.failure(message);
      }

      if (currentUser != null) {
        await ReminderNotificationService.instance.cancelAll();
        await AppDatabase.instance.clearUserData(currentUser.id);
      }
      await LocalStorage.removeToken();
      await LocalStorage.removeUser();
      ref.read(userProvider.notifier).state = null;
      state = false;

      return AuthActionResult.success(message);
    } on StateError catch (e) {
      return AuthActionResult.failure(e.message);
    } catch (_) {
      return const AuthActionResult.failure('Network error occurred');
    }
  }

  Future<void> logout() async {
    if (AppMode.uiOnly) {
      ref.read(userProvider.notifier).state = _mockUser;
      state = true;
      return;
    }

    final currentUser =
        ref.read(userProvider) ?? await LocalStorage.getCachedUser();
    if (currentUser != null) {
      try {
        await const SyncService().syncNow(currentUser.id);
      } catch (_) {
        // Logout tetap membersihkan cache lokal walau sync terakhir gagal.
      }
    }

    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Keep logout local even if server request fails.
    }
    if (currentUser != null) {
      await ReminderNotificationService.instance.cancelAll();
      await AppDatabase.instance.clearUserData(currentUser.id);
    }
    await LocalStorage.removeToken();
    await LocalStorage.removeUser();
    ref.read(userProvider.notifier).state = null;
    state = false;
  }

  String _messageFromResponse(String responseBody, String fallback) {
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final errors = body['errors'];

      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }

      return body['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<AuthActionResult> _persistUserActionResponse(
    String responseBody,
    int statusCode, {
    required String successFallback,
    required String failureFallback,
  }) async {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final message = _messageFromResponse(
      responseBody,
      isSuccess ? successFallback : failureFallback,
    );

    if (!isSuccess) {
      return AuthActionResult.failure(message);
    }

    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final data = body['data'];
      final userData = data is Map ? data['user'] : null;

      if (userData is Map) {
        final user = User.fromJson(Map<String, dynamic>.from(userData));
        await LocalStorage.saveUser(user);
        ref.read(userProvider.notifier).state = user;
        state = true;
      }
    } catch (_) {
      // Keep the successful action result even if response parsing fails.
    }

    return AuthActionResult.success(message);
  }

  String? _nullableString(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }
}

final authProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref);
});
