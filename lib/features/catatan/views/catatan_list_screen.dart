import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/auth/models/user_model.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/catatan/models/catatan_model.dart';
import 'package:mobile_ver/features/catatan/providers/catatan_provider.dart';
import 'package:mobile_ver/features/catatan/views/catatan_form_screen.dart';
import 'package:mobile_ver/features/profile/widgets/profile_avatar.dart';

class CatatanListScreen extends ConsumerStatefulWidget {
  const CatatanListScreen({super.key});

  @override
  ConsumerState<CatatanListScreen> createState() => _CatatanListScreenState();
}

class _CatatanListScreenState extends ConsumerState<CatatanListScreen> {
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final catatanAsyncValue = ref.watch(catatanProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: catatanAsyncValue.when(
          data: (rows) {
            final activeNotes =
                rows.where((item) => !item.statusSampah).toList()
                  ..sort((a, b) => b.tanggalAsDate.compareTo(a.tanggalAsDate));
            final trashNotes = rows.where((item) => item.statusSampah).toList()
              ..sort((a, b) => b.tanggalAsDate.compareTo(a.tanggalAsDate));

            return RefreshIndicator(
              color: context.appPrimary,
              onRefresh: () async {
                await ref
                    .read(catatanProvider.notifier)
                    .fetchCatatan(showLoader: false);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _TopBar(
                    user: user,
                    userName: user?.displayName ?? 'Pengguna',
                    onOpenProfile: () => context.push('/profile'),
                    onOpenNotifications: () => context.go('/pengumuman'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Catatan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineActionButton(
                          label: 'Sampah (${trashNotes.length})',
                          icon: Icons.delete_outline_rounded,
                          onTap: () => _openTrashSheet(trashNotes),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PrimaryActionButton(
                          label: 'Catatan Baru',
                          icon: Icons.add_rounded,
                          onTap: _openCreateForm,
                        ),
                      ),
                    ],
                  ),
                  if (_successMessage != null) ...[
                    const SizedBox(height: 14),
                    _SuccessBanner(
                      message: _successMessage!,
                      onClose: () => setState(() => _successMessage = null),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (activeNotes.isEmpty)
                    const _CatatanEmptyStateCard()
                  else
                    Column(
                      children: [
                        for (var i = 0; i < activeNotes.length; i++) ...[
                          _CatatanFeedCard(
                            item: activeNotes[i],
                            onTap: () => _openEditForm(activeNotes[i]),
                            onLongPress: () => _openNoteActions(activeNotes[i]),
                          ),
                          if (i != activeNotes.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorState(
            message: 'Gagal memuat catatan.',
            onRetry: () => ref.read(catatanProvider.notifier).fetchCatatan(),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateForm() async {
    final result = await Navigator.of(context).push<CatatanFormResult>(
      MaterialPageRoute(builder: (_) => const CatatanFormScreen()),
    );
    if (!mounted) {
      return;
    }

    if (result == CatatanFormResult.created) {
      setState(() {
        _successMessage = 'Catatan berhasil ditambahkan.';
      });
    }
  }

  Future<void> _openEditForm(Catatan catatan) async {
    Catatan target = catatan;

    if (!catatan.hasFullIsi) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final detail = await ref
          .read(catatanProvider.notifier)
          .fetchCatatanDetail(catatan.id);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (detail == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat isi penuh catatan.')),
          );
        }
        return;
      }

      target = detail;
    }

    if (!mounted) {
      return;
    }

    final result = await Navigator.of(context).push<CatatanFormResult>(
      MaterialPageRoute(builder: (_) => CatatanFormScreen(catatan: target)),
    );
    if (!mounted) {
      return;
    }

    if (result == CatatanFormResult.updated) {
      setState(() {
        _successMessage = 'Catatan berhasil diperbarui.';
      });
    }
  }

  Future<void> _openNoteActions(Catatan catatan) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit catatan'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEditForm(catatan);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE25555),
                ),
                title: const Text(
                  'Pindahkan ke sampah',
                  style: TextStyle(color: Color(0xFFE25555)),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmMoveToTrash(catatan);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmMoveToTrash(Catatan catatan) async {
    final move = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pindahkan ke Sampah'),
          content: Text('Pindahkan "${catatan.judul}" ke sampah?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Pindahkan'),
            ),
          ],
        );
      },
    );

    if (move != true || !mounted) {
      return;
    }

    final success = await ref
        .read(catatanProvider.notifier)
        .deleteCatatan(catatan.id);
    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _successMessage = 'Catatan dipindahkan ke sampah.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal memindahkan catatan ke sampah.')),
    );
  }

  Future<void> _openTrashSheet(List<Catatan> trashNotes) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Sampah Catatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF231D34),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${trashNotes.length} item',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF7B8197),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (trashNotes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada catatan di sampah.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.56,
                    child: ListView.separated(
                      itemCount: trashNotes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = trashNotes[index];
                        final tone = _resolveCatatanTone(item);

                        return Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: tone.accentColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.judul,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: context.appText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _catatanPreviewLabel(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: context.appMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  IconButton(
                                    tooltip: 'Pulihkan',
                                    onPressed: () => _restoreFromTrash(item),
                                    icon: const Icon(Icons.restore_rounded),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus permanen',
                                    onPressed: () => _forceDelete(item),
                                    icon: const Icon(
                                      Icons.delete_forever_rounded,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _restoreFromTrash(Catatan item) async {
    final success = await ref
        .read(catatanProvider.notifier)
        .restoreCatatan(item.id);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      setState(() {
        _successMessage = 'Catatan dipulihkan dari sampah.';
      });
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gagal memulihkan catatan.')));
  }

  Future<void> _forceDelete(Catatan item) async {
    final success = await ref
        .read(catatanProvider.notifier)
        .forceDeleteCatatan(item.id);
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
      setState(() {
        _successMessage = 'Catatan dihapus permanen.';
      });
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gagal menghapus catatan.')));
  }
}

class _TopBar extends StatelessWidget {
  final User? user;
  final String userName;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotifications;

  const _TopBar({
    required this.user,
    required this.userName,
    required this.onOpenProfile,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onOpenProfile,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    ProfileAvatar(
                      user: user,
                      fallbackName: userName,
                      size: 46,
                      borderWidth: 2,
                      gradientColors: const [
                        Color(0xFFE3E8FF),
                        Color(0xFFB9C6FF),
                      ],
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                      initialsStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3440C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3542D4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _IconCapsuleButton(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: onOpenNotifications,
        ),
      ],
    );
  }
}

class _CatatanFeedCard extends StatelessWidget {
  final Catatan item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CatatanFeedCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _resolveCatatanTone(item);
    final preview = _catatanPreviewLabel(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: context.appCardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: tone.accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tone.badgeBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tone.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tone.badgeForeground,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: context.appMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: context.appFaint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _catatanTimeLabel(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.appFaint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4E44F2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        elevation: 0,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.appPrimary,
        side: BorderSide(color: context.appBorder),
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _SuccessBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7E7CB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF166534),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: const Color(0xFF166534),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CatatanEmptyStateCard extends StatelessWidget {
  const _CatatanEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada catatan aktif.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan catatan baru untuk menyimpan ide, materi, atau daftar belanja harianmu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4E44F2),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCapsuleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  const _IconCapsuleButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(child: Icon(icon, color: context.appText, size: 22)),
              if (showDot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatatanTone {
  final String label;
  final Color accentColor;
  final Color badgeBackground;
  final Color badgeForeground;

  const _CatatanTone({
    required this.label,
    required this.accentColor,
    required this.badgeBackground,
    required this.badgeForeground,
  });
}

_CatatanTone _resolveCatatanTone(Catatan item) {
  final text = '${item.judul} ${item.listPreview}'.toLowerCase();

  if (_containsAny(text, [
    'belanja',
    'uang',
    'budget',
    'makan',
    'tagihan',
    'beli',
  ])) {
    return const _CatatanTone(
      label: 'BELANJA',
      accentColor: Color(0xFF5A50E8),
      badgeBackground: Color(0xFFF0EEFF),
      badgeForeground: Color(0xFF5A50E8),
    );
  }

  if (_containsAny(text, [
    'kuliah',
    'materi',
    'kelas',
    'dosen',
    'tugas',
    'uts',
    'uas',
    'praktikum',
  ])) {
    return const _CatatanTone(
      label: 'KULIAH',
      accentColor: Color(0xFFFF8A2A),
      badgeBackground: Color(0xFFFFF1E5),
      badgeForeground: Color(0xFFD46F18),
    );
  }

  if (_containsAny(text, [
    'ide',
    'proyek',
    'project',
    'konsep',
    'startup',
    'riset',
  ])) {
    return const _CatatanTone(
      label: 'IDE',
      accentColor: Color(0xFFC15EFF),
      badgeBackground: Color(0xFFF8ECFF),
      badgeForeground: Color(0xFFB34BEF),
    );
  }

  return const _CatatanTone(
    label: 'UMUM',
    accentColor: Color(0xFFD9E4F0),
    badgeBackground: Color(0xFFF3F6F9),
    badgeForeground: Color(0xFF7B8794),
  );
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any(text.contains);
}

String _catatanPreviewLabel(Catatan item) {
  if (!item.showPreview) {
    return 'Preview disembunyikan';
  }

  return item.listPreview.isEmpty ? 'Catatan tanpa isi.' : item.listPreview;
}

String _catatanTimeLabel(Catatan item) {
  final now = DateTime.now();
  final noteDate = item.tanggalAsDate;
  final dayLabel = _relativeDayLabel(noteDate, now);
  final createdAt = item.createdAt;

  if (createdAt != null) {
    return '$dayLabel, ${DateFormat('HH:mm', 'id_ID').format(createdAt)}';
  }

  return dayLabel;
}

String _relativeDayLabel(DateTime value, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) {
    return 'Hari ini';
  }

  if (difference == 1) {
    return 'Kemarin';
  }

  return DateFormat('dd MMM yyyy', 'id_ID').format(value);
}
