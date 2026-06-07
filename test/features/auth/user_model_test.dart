import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';

void main() {
  group('User model', () {
    test('parses nested affiliation and profile payloads', () {
      final user = User.fromJson({
        'id': '42',
        'name': 'Nama Login',
        'email': 'user@example.test',
        'role': 'user',
        'role_label': 'Pengguna',
        'admin_level': '0',
        'account_status': 'active',
        'email_verified_at': '2026-05-13T01:00:00Z',
        'affiliation': {
          'type': 'university',
          'name': 'Universitas Contoh',
          'student_id_type': 'nim',
          'student_id_number': '123456',
          'status': 'verified',
        },
        'profile': {
          'display_name': 'Nama Workspace',
          'bio': 'Mahasiswa',
          'phone': '081234',
          'location': 'Jakarta',
          'theme_preference': 'dark',
          'timezone': 'Asia/Jakarta',
          'locale': 'id',
          'has_avatar': true,
          'avatar_url': '/api/v1/profile/avatar',
        },
      });

      expect(user.id, 42);
      expect(user.displayName, 'Nama Workspace');
      expect(user.hasVerifiedEmail, isTrue);
      expect(user.affiliation?.name, 'Universitas Contoh');
      expect(user.affiliation?.hasAnyDetail, isTrue);
      expect(user.profile?.themePreference, 'dark');
      expect(user.profile?.hasAvatar, isTrue);
    });

    test('falls back to account name when display name is empty', () {
      final user = User.fromJson({
        'id': 7,
        'name': 'Nama Akun',
        'email': 'akun@example.test',
        'profile': {'display_name': '   '},
      });

      expect(user.displayName, 'Nama Akun');
      expect(user.hasVerifiedEmail, isFalse);
      expect(user.profile?.hasAnyDetail, isFalse);
    });
  });
}
