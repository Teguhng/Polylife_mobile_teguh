import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/profile/widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _locationController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _affiliationNameController = TextEditingController();
  final _studentIdNumberController = TextEditingController();
  String _gender = '';
  String _themePreference = 'system';
  String _locale = 'id';
  String _affiliationType = 'university';
  String _studentIdType = 'nim';
  bool _isSaving = false;
  bool _isAvatarBusy = false;
  bool _isPasswordSaving = false;
  bool _isAffiliationEditing = false;
  bool _isAffiliationSaving = false;
  bool _isDeletingAccount = false;
  String? _lastProfileFormSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshProfile(showError: false);
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _locationController.dispose();
    _timezoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _affiliationNameController.dispose();
    _studentIdNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final palette = _ProfilePalette.of(context);
    if (user != null) {
      _hydrateProfileFormIfNeeded(user);
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: palette.primary,
          onRefresh: _refreshProfile,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _TitleBar(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }

                  context.go('/');
                },
                onRefresh: _refreshProfile,
                onEdit: null,
                onCancelEdit: null,
                isEditing: false,
              ),
              const SizedBox(height: 16),
              if (user == null)
                const _EmptySessionCard()
              else ...[
                _ProfileHeaderCard(user: user),
                const SizedBox(height: 14),
                _AvatarActionCard(
                  isBusy: _isAvatarBusy,
                  hasAvatar: user.profile?.hasAvatar == true,
                  onPickAvatar: _pickAvatar,
                  onDeleteAvatar: _deleteAvatar,
                ),
                const SizedBox(height: 14),
                _InfoSection(
                  title: 'Akun',
                  rows: [
                    _InfoRowData(
                      icon: Icons.badge_outlined,
                      label: 'Nama akun',
                      value: user.name,
                    ),
                    _InfoRowData(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: user.email,
                    ),
                    _InfoRowData(
                      icon: Icons.verified_user_outlined,
                      label: 'Status akun',
                      value: _accountStatusLabel(user.accountStatus),
                    ),
                    _InfoRowData(
                      icon: Icons.mark_email_read_outlined,
                      label: 'Verifikasi email',
                      value: user.hasVerifiedEmail
                          ? 'Terverifikasi'
                          : 'Belum terverifikasi',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ProfileEditSection(
                  isSaving: _isSaving,
                  displayNameController: _displayNameController,
                  bioController: _bioController,
                  phoneController: _phoneController,
                  dateOfBirthController: _dateOfBirthController,
                  locationController: _locationController,
                  timezoneController: _timezoneController,
                  gender: _gender,
                  themePreference: _themePreference,
                  locale: _locale,
                  onGenderChanged: (value) =>
                      setState(() => _gender = value ?? ''),
                  onThemeChanged: (value) =>
                      setState(() => _themePreference = value ?? 'system'),
                  onLocaleChanged: (value) =>
                      setState(() => _locale = value ?? 'id'),
                  onSave: _saveProfile,
                ),
                const SizedBox(height: 14),
                _AffiliationSection(
                  user: user,
                  isEditing: _isAffiliationEditing,
                  isSaving: _isAffiliationSaving,
                  affiliationNameController: _affiliationNameController,
                  studentIdNumberController: _studentIdNumberController,
                  affiliationType: _affiliationType,
                  studentIdType: _studentIdType,
                  onTypeChanged: (value) =>
                      setState(() => _affiliationType = value ?? 'university'),
                  onStudentIdTypeChanged: (value) =>
                      setState(() => _studentIdType = value ?? 'nim'),
                  onShowForm: () => _startAffiliationEditing(user),
                  onCancelForm: _stopAffiliationEditing,
                  onSubmit: _submitAffiliationRequest,
                  onCancelPending: _cancelAffiliationRequest,
                ),
                const SizedBox(height: 16),
                _SecuritySection(
                  currentPasswordController: _currentPasswordController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  isSaving: _isPasswordSaving,
                  onSubmit: _updatePassword,
                ),
                const SizedBox(height: 14),
                _DangerZoneSection(
                  isDeleting: _isDeletingAccount,
                  onDeleteAccount: _confirmDeleteAccount,
                ),
                const SizedBox(height: 14),
                _LogoutButton(onTap: _logout),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshProfile({bool showError = true}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(authProvider.notifier).refreshCurrentUser();
    if (!mounted || result.isSuccess || !showError) return;

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      router.go('/login');
    }
  }

  void _hydrateProfileFormIfNeeded(User user) {
    if (_isSaving) {
      return;
    }

    final profile = user.profile;
    final signature = [
      profile?.displayName ?? '',
      profile?.bio ?? '',
      profile?.phone ?? '',
      profile?.dateOfBirth ?? '',
      profile?.location ?? '',
      profile?.timezone ?? '',
      profile?.gender ?? '',
      profile?.themePreference ?? '',
      profile?.locale ?? '',
    ].join('\u001F');

    if (_lastProfileFormSignature == signature) {
      return;
    }

    _lastProfileFormSignature = signature;
    _fillProfileControllers(user);
  }

  void _fillProfileControllers(User user) {
    final profile = user.profile;

    _displayNameController.text = profile?.displayName ?? '';
    _bioController.text = profile?.bio ?? '';
    _phoneController.text = profile?.phone ?? '';
    _dateOfBirthController.text = profile?.dateOfBirth ?? '';
    _locationController.text = profile?.location ?? '';
    _timezoneController.text = profile?.timezone ?? 'Asia/Jakarta';
    _gender = _allowedValue(profile?.gender, const {
      '',
      'female',
      'male',
      'other',
      'prefer_not_to_say',
    }, '');
    _themePreference = _allowedValue(profile?.themePreference, const {
      'system',
      'light',
      'dark',
    }, 'system');
    _locale = _allowedValue(profile?.locale, const {'id', 'en'}, 'id');
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    final result = await ref
        .read(authProvider.notifier)
        .updateProfile(
          displayName: _displayNameController.text,
          bio: _bioController.text,
          phone: _phoneController.text,
          dateOfBirth: _dateOfBirthController.text,
          gender: _gender,
          location: _locationController.text,
          themePreference: _themePreference,
          timezone: _timezoneController.text,
          locale: _locale,
        );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (result.isSuccess) {
        final updatedUser = ref.read(userProvider);
        if (updatedUser != null) {
          _lastProfileFormSignature = null;
          _hydrateProfileFormIfNeeded(updatedUser);
        }
      }
    });

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _pickAvatar() async {
    if (_isAvatarBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 75,
      requestFullMetadata: false,
    );

    if (image == null) return;

    setState(() => _isAvatarBusy = true);
    AuthActionResult result;

    try {
      final avatarBytes = await _prepareAvatarBytesForUpload(image);
      result = await ref
          .read(authProvider.notifier)
          .uploadProfileAvatarBytes(avatarBytes);
    } catch (error) {
      result = AuthActionResult.failure(
        'Foto profil gagal diproses di aplikasi: $error',
      );
    }

    if (!mounted) return;
    setState(() => _isAvatarBusy = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<Uint8List> _prepareAvatarBytesForUpload(XFile image) async {
    final compressed = await _compressAvatarWithNativeCodec(image);
    if (compressed != null) {
      return _normalizeAvatarBytes(compressed);
    }

    return _normalizeAvatarBytes(await image.readAsBytes());
  }

  Uint8List _normalizeAvatarBytes(Uint8List sourceBytes) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('Unsupported avatar image.');
    }

    final oriented = img.bakeOrientation(decoded);
    final squareSize = oriented.width < oriented.height
        ? oriented.width
        : oriented.height;
    final cropped = img.copyCrop(
      oriented,
      x: (oriented.width - squareSize) ~/ 2,
      y: (oriented.height - squareSize) ~/ 2,
      width: squareSize,
      height: squareSize,
    );
    final resized = img.copyResize(
      cropped,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.average,
    );
    final encoded = img.encodeJpg(resized, quality: 82);

    return Uint8List.fromList(encoded);
  }

  Future<Uint8List?> _compressAvatarWithNativeCodec(XFile image) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 256,
        minHeight: 256,
        quality: 82,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (result == null) {
        return null;
      }

      if (result.isEmpty) {
        return null;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteAvatar() async {
    if (_isAvatarBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAvatarBusy = true);
    final result = await ref.read(authProvider.notifier).deleteProfileAvatar();

    if (!mounted) return;
    setState(() => _isAvatarBusy = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _startAffiliationEditing(User user) {
    final affiliation = user.affiliation;

    _affiliationType = _allowedValue(
      affiliation?.type,
      _affiliationTypeOptions.keys.toSet(),
      'university',
    );
    _studentIdType = _allowedValue(
      affiliation?.studentIdType,
      _identityTypeOptions.keys.toSet(),
      'nim',
    );
    _affiliationNameController.text = affiliation?.name ?? '';
    _studentIdNumberController.text = affiliation?.studentIdNumber ?? '';

    setState(() => _isAffiliationEditing = true);
  }

  void _stopAffiliationEditing() {
    if (_isAffiliationSaving) return;
    setState(() => _isAffiliationEditing = false);
  }

  Future<void> _submitAffiliationRequest() async {
    if (_isAffiliationSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAffiliationSaving = true);

    final result = await ref
        .read(authProvider.notifier)
        .submitAffiliationRequest(
          affiliationType: _affiliationType,
          affiliationName: _affiliationNameController.text,
          studentIdType: _studentIdType,
          studentIdNumber: _studentIdNumberController.text,
        );

    if (!mounted) return;
    setState(() {
      _isAffiliationSaving = false;
      if (result.isSuccess) {
        _isAffiliationEditing = false;
      }
    });
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _cancelAffiliationRequest() async {
    if (_isAffiliationSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAffiliationSaving = true);
    final result = await ref
        .read(authProvider.notifier)
        .cancelAffiliationRequest();

    if (!mounted) return;
    setState(() => _isAffiliationSaving = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _updatePassword() async {
    if (_isPasswordSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _isPasswordSaving = true);

    final result = await ref
        .read(authProvider.notifier)
        .updatePassword(
          currentPassword: _currentPasswordController.text,
          password: _newPasswordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (!mounted) return;
    setState(() => _isPasswordSaving = false);
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    if (result.isSuccess) {
      router.go('/login');
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) return;

    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus akun?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Akun dan data workspace terkait akan dihapus permanen. Masukkan password untuk konfirmasi.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE25555),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus akun'),
            ),
          ],
        );
      },
    );

    final password = passwordController.text;
    passwordController.dispose();
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _isDeletingAccount = true);
    final result = await ref
        .read(authProvider.notifier)
        .deleteAccount(password: password);

    if (!mounted) return;
    setState(() => _isDeletingAccount = false);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    if (result.isSuccess) {
      router.go('/login');
    }
  }
}

class _TitleBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onEdit;
  final VoidCallback? onCancelEdit;
  final bool isEditing;

  const _TitleBar({
    required this.onBack,
    required this.onRefresh,
    required this.onEdit,
    required this.onCancelEdit,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Row(
      children: [
        _CircleActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Profil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
        ),
        _CircleActionButton(icon: Icons.refresh_rounded, onTap: onRefresh),
        if (onEdit != null || onCancelEdit != null) ...[
          const SizedBox(width: 8),
          _CircleActionButton(
            icon: isEditing ? Icons.close_rounded : Icons.edit_outlined,
            onTap: isEditing ? onCancelEdit : onEdit,
          ),
        ],
      ],
    );
  }
}

class _AvatarActionCard extends StatelessWidget {
  final bool isBusy;
  final bool hasAvatar;
  final VoidCallback onPickAvatar;
  final VoidCallback onDeleteAvatar;

  const _AvatarActionCard({
    required this.isBusy,
    required this.hasAvatar,
    required this.onPickAvatar,
    required this.onDeleteAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.photo_camera_outlined, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isBusy ? 'Memproses foto...' : 'Foto profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ),
          _SmallActionButton(
            label: 'Pilih',
            onTap: isBusy ? null : onPickAvatar,
          ),
          if (hasAvatar) ...[
            const SizedBox(width: 8),
            _SmallActionButton(
              label: 'Hapus',
              isDanger: true,
              onTap: isBusy ? null : onDeleteAvatar,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDanger;

  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);
    final disabled = onTap == null;
    final background = isPrimary
        ? palette.primary
        : isDanger
        ? palette.dangerSoft
        : palette.subtle;
    final foreground = isPrimary
        ? Colors.white
        : isDanger
        ? const Color(0xFFE25555)
        : palette.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: disabled ? 0.55 : 1,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? palette.primary
                    : isDanger
                    ? palette.dangerBorder
                    : palette.border,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
        decoration: _fieldDecoration(context, label, hintText),
      ),
    );
  }
}

class _ProfilePasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _ProfilePasswordField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
        decoration: _fieldDecoration(context, label, null),
      ),
    );
  }
}

class _ProfileSelectField extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _ProfileSelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: items.containsKey(value) ? value : items.keys.first,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
        dropdownColor: palette.surface,
        decoration: _fieldDecoration(context, label, null),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ProfileEditSection extends StatelessWidget {
  final bool isSaving;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final TextEditingController phoneController;
  final TextEditingController dateOfBirthController;
  final TextEditingController locationController;
  final TextEditingController timezoneController;
  final String gender;
  final String themePreference;
  final String locale;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String?> onThemeChanged;
  final ValueChanged<String?> onLocaleChanged;
  final VoidCallback onSave;

  const _ProfileEditSection({
    required this.isSaving,
    required this.displayNameController,
    required this.bioController,
    required this.phoneController,
    required this.dateOfBirthController,
    required this.locationController,
    required this.timezoneController,
    required this.gender,
    required this.themePreference,
    required this.locale,
    required this.onGenderChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileTextField(
            label: 'Nama tampilan',
            controller: displayNameController,
            maxLength: 100,
          ),
          _ProfileTextField(
            label: 'Nomor kontak',
            controller: phoneController,
            maxLength: 30,
            keyboardType: TextInputType.phone,
          ),
          _ProfileTextField(
            label: 'Tanggal lahir',
            controller: dateOfBirthController,
            hintText: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          _ProfileSelectField(
            label: 'Gender',
            value: gender,
            onChanged: onGenderChanged,
            items: const {
              '': 'Tidak diisi',
              'female': 'Perempuan',
              'male': 'Laki-laki',
              'other': 'Lainnya',
              'prefer_not_to_say': 'Pilih untuk tidak menyebutkan',
            },
          ),
          _ProfileTextField(
            label: 'Lokasi',
            controller: locationController,
            maxLength: 120,
          ),
          _ProfileSelectField(
            label: 'Tema profil',
            value: themePreference,
            onChanged: onThemeChanged,
            items: const {
              'system': 'Ikuti perangkat',
              'light': 'Light',
              'dark': 'Dark',
            },
          ),
          _ProfileTextField(
            label: 'Zona waktu',
            controller: timezoneController,
            maxLength: 64,
            hintText: 'Asia/Jakarta',
          ),
          _ProfileSelectField(
            label: 'Bahasa',
            value: locale,
            onChanged: onLocaleChanged,
            items: const {'id': 'Indonesia', 'en': 'English'},
          ),
          _ProfileTextField(
            label: 'Bio singkat',
            controller: bioController,
            maxLength: 500,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          _SmallActionButton(
            label: isSaving ? 'Menyimpan...' : 'Simpan profil',
            isPrimary: true,
            onTap: isSaving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _AffiliationSection extends StatelessWidget {
  final User user;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController affiliationNameController;
  final TextEditingController studentIdNumberController;
  final String affiliationType;
  final String studentIdType;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStudentIdTypeChanged;
  final VoidCallback onShowForm;
  final VoidCallback onCancelForm;
  final VoidCallback onSubmit;
  final VoidCallback onCancelPending;

  const _AffiliationSection({
    required this.user,
    required this.isEditing,
    required this.isSaving,
    required this.affiliationNameController,
    required this.studentIdNumberController,
    required this.affiliationType,
    required this.studentIdType,
    required this.onTypeChanged,
    required this.onStudentIdTypeChanged,
    required this.onShowForm,
    required this.onCancelForm,
    required this.onSubmit,
    required this.onCancelPending,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);
    final affiliation = user.affiliation;
    final pendingRequest = affiliation?.pendingRequest;
    final hasVerifiedAffiliation =
        affiliation?.status == 'verified' &&
        ((affiliation?.name ?? '').trim().isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kampus dan Identitas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            data: _InfoRowData(
              icon: Icons.school_outlined,
              label: 'Afiliasi aktif',
              value:
                  '${_displayValue(affiliation?.name)} · ${_affiliationStatusLabel(affiliation?.status)}',
            ),
          ),
          Divider(height: 1, color: palette.border),
          _InfoRow(
            data: _InfoRowData(
              icon: Icons.confirmation_number_outlined,
              label: _studentIdLabel(affiliation?.studentIdType),
              value: _displayValue(affiliation?.studentIdNumber),
            ),
          ),
          if (pendingRequest != null) ...[
            const SizedBox(height: 12),
            _InlineNotice(
              icon: Icons.hourglass_top_rounded,
              title: 'Pengajuan menunggu review',
              message:
                  '${_affiliationTypeLabel(pendingRequest.type)} - ${_displayValue(pendingRequest.name)}',
              foreground: const Color(0xFFB45309),
              background: const Color(0xFFFFF7E6),
            ),
            const SizedBox(height: 10),
            _SmallActionButton(
              label: isSaving ? 'Membatalkan...' : 'Batalkan pengajuan',
              isDanger: true,
              onTap: isSaving ? null : onCancelPending,
            ),
          ] else if (!isEditing) ...[
            const SizedBox(height: 12),
            _SmallActionButton(
              label: hasVerifiedAffiliation
                  ? 'Ajukan pindah afiliasi'
                  : 'Ajukan afiliasi',
              isPrimary: true,
              onTap: onShowForm,
            ),
          ],
          if (isEditing) ...[
            const SizedBox(height: 14),
            _ProfileSelectField(
              label: 'Jenis afiliasi',
              value: affiliationType,
              items: _affiliationTypeOptions,
              onChanged: onTypeChanged,
            ),
            _ProfileTextField(
              label: 'Nama afiliasi',
              controller: affiliationNameController,
              maxLength: 160,
            ),
            _ProfileSelectField(
              label: 'Tipe identitas',
              value: studentIdType,
              items: _identityTypeOptions,
              onChanged: onStudentIdTypeChanged,
            ),
            _ProfileTextField(
              label: 'Nomor identitas',
              controller: studentIdNumberController,
              maxLength: 64,
            ),
            Row(
              children: [
                Expanded(
                  child: _SmallActionButton(
                    label: 'Batal',
                    onTap: isSaving ? null : onCancelForm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallActionButton(
                    label: isSaving ? 'Mengirim...' : 'Submit',
                    isPrimary: true,
                    onTap: isSaving ? null : onSubmit,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isSaving;
  final VoidCallback onSubmit;

  const _SecuritySection({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isSaving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ubah password akan memutus token API, lalu kamu perlu login kembali.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePasswordField(
            label: 'Password saat ini',
            controller: currentPasswordController,
          ),
          _ProfilePasswordField(
            label: 'Password baru',
            controller: newPasswordController,
          ),
          _ProfilePasswordField(
            label: 'Konfirmasi password baru',
            controller: confirmPasswordController,
          ),
          const SizedBox(height: 4),
          _SmallActionButton(
            label: isSaving ? 'Menyimpan...' : 'Simpan password',
            isPrimary: true,
            onTap: isSaving ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _DangerZoneSection extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onDeleteAccount;

  const _DangerZoneSection({
    required this.isDeleting,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.dangerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area Berbahaya',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE25555),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hapus akun akan membersihkan sesi dan data lokal akun ini dari perangkat.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 12),
          _SmallActionButton(
            label: isDeleting ? 'Menghapus...' : 'Hapus akun',
            isDanger: true,
            onTap: isDeleting ? null : onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color foreground;
  final Color background;

  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final User user;

  const _ProfileHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            user: user,
            fallbackName: user.displayName,
            size: 64,
            borderWidth: 3,
            gradientColors: const [Color(0xFFE3E8FF), Color(0xFF6C63FF)],
            boxShadow: const [
              BoxShadow(
                color: Color(0x244B3FF2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
            initialsStyle: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      icon: Icons.person_rounded,
                      label: user.roleLabel,
                      foreground: const Color(0xFF4B3FF2),
                      background: const Color(0xFFEDEBFF),
                    ),
                    _StatusChip(
                      icon: user.hasVerifiedEmail
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      label: user.hasVerifiedEmail
                          ? 'Email aman'
                          : 'Email belum valid',
                      foreground: user.hasVerifiedEmail
                          ? const Color(0xFF14804A)
                          : const Color(0xFFB45309),
                      background: user.hasVerifiedEmail
                          ? const Color(0xFFE5F8ED)
                          : const Color(0xFFFFF3DA),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRowData> rows;

  const _InfoSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(data: rows[i]),
            if (i != rows.length - 1) Divider(height: 1, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final _InfoRowData data;

  const _InfoRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: palette.subtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 18, color: palette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.dangerBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFE25555)),
              const SizedBox(width: 12),
              Text(
                'Keluar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE25555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySessionCard extends StatelessWidget {
  const _EmptySessionCard();

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Sesi profil belum tersedia.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: palette.muted,
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _ProfilePalette.of(context);

    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: onTap == null ? 0.5 : 1,
          child: SizedBox(
            height: 42,
            width: 42,
            child: Icon(icon, color: palette.icon, size: 21),
          ),
        ),
      ),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

const Map<String, String> _affiliationTypeOptions = {
  'school': 'Sekolah',
  'university': 'Universitas',
  'institute': 'Institut',
  'polytechnic': 'Politeknik',
  'academy': 'Akademi',
  'organization': 'Organisasi',
  'company': 'Perusahaan',
  'foundation': 'Yayasan',
  'other': 'Lainnya',
};

const Map<String, String> _identityTypeOptions = {
  'nim': 'NIM',
  'nrp': 'NRP',
  'nisn': 'NISN',
  'nidn': 'NIDN',
  'nip': 'NIP',
  'other': 'Lainnya',
};

String _displayValue(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? 'Belum diisi' : text;
}

String _accountStatusLabel(String value) {
  switch (value.toLowerCase()) {
    case 'active':
      return 'Aktif';
    case 'banned':
      return 'Diblokir';
    case 'inactive':
      return 'Tidak aktif';
  }

  return _displayValue(value);
}

String _affiliationStatusLabel(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'verified':
      return 'Terverifikasi';
    case 'rejected':
      return 'Ditolak';
    case 'pending':
      return 'Menunggu verifikasi';
  }

  return _displayValue(value);
}

String _affiliationTypeLabel(String? value) {
  final normalized = (value ?? '').toLowerCase().trim();
  return _affiliationTypeOptions[normalized] ?? _displayValue(value);
}

String _studentIdLabel(String? value) {
  final normalized = (value ?? '').trim().toUpperCase();
  return normalized.isEmpty ? 'Identitas' : normalized;
}

InputDecoration _fieldDecoration(
  BuildContext context,
  String label,
  String? hintText,
) {
  final palette = _ProfilePalette.of(context);

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    counterText: '',
    filled: true,
    fillColor: palette.fieldFill,
    labelStyle: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: palette.muted,
    ),
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: palette.placeholder,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.primary, width: 1.4),
    ),
  );
}

class _ProfilePalette {
  final Color background;
  final Color surface;
  final Color subtle;
  final Color fieldFill;
  final Color text;
  final Color muted;
  final Color placeholder;
  final Color primary;
  final Color border;
  final Color icon;
  final Color dangerSoft;
  final Color dangerBorder;
  final List<BoxShadow> cardShadow;

  const _ProfilePalette({
    required this.background,
    required this.surface,
    required this.subtle,
    required this.fieldFill,
    required this.text,
    required this.muted,
    required this.placeholder,
    required this.primary,
    required this.border,
    required this.icon,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.cardShadow,
  });

  factory _ProfilePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return _ProfilePalette(
        background: theme.scaffoldBackgroundColor,
        surface: scheme.surface,
        subtle: const Color(0xFF1E293B),
        fieldFill: const Color(0xFF0F172A),
        text: const Color(0xFFF8FAFC),
        muted: const Color(0xFF94A3B8),
        placeholder: const Color(0xFF64748B),
        primary: scheme.primary,
        border: const Color(0xFF334155),
        icon: const Color(0xFFCBD5E1),
        dangerSoft: const Color(0xFF3F1D2B),
        dangerBorder: const Color(0xFF7F1D1D),
        cardShadow: const [],
      );
    }

    return _ProfilePalette(
      background: theme.scaffoldBackgroundColor,
      surface: scheme.surface,
      subtle: const Color(0xFFF5F4FA),
      fieldFill: const Color(0xFFF8F7FC),
      text: const Color(0xFF211C31),
      muted: const Color(0xFF7A819C),
      placeholder: const Color(0xFF9DA3B8),
      primary: scheme.primary,
      border: const Color(0xFFE7E3F3),
      icon: const Color(0xFF565C75),
      dangerSoft: const Color(0xFFFFF1F2),
      dangerBorder: const Color(0xFFFFD4D4),
      cardShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}

String _allowedValue(String? value, Set<String> allowed, String fallback) {
  final normalized = value?.trim() ?? '';
  return allowed.contains(normalized) ? normalized : fallback;
}
