import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/config/api_config.dart';
import 'package:mobile_ver/core/media/local_image_cache.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/pengumuman/models/pengumuman_model.dart';
import 'package:mobile_ver/features/pengumuman/providers/pengumuman_provider.dart';
import 'dart:typed_data';

class PengumumanListScreen extends ConsumerWidget {
  const PengumumanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengumumanAsync = ref.watch(pengumumanProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: pengumumanAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return RefreshIndicator(
                color: context.appPrimary,
                onRefresh: () =>
                    ref.read(pengumumanProvider.notifier).fetchPengumuman(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _HeaderRow(
                      onRefresh: () => ref
                          .read(pengumumanProvider.notifier)
                          .fetchPengumuman(),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Kegiatan Kampus',
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 18),
                    _EmptyActivityState(),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: context.appPrimary,
              onRefresh: () =>
                  ref.read(pengumumanProvider.notifier).fetchPengumuman(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length + 2,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _HeaderRow(
                      onRefresh: () => ref
                          .read(pengumumanProvider.notifier)
                          .fetchPengumuman(),
                    );
                  }

                  if (index == 1) {
                    return Text(
                      'Kegiatan Kampus',
                      style: GoogleFonts.plusJakartaSans(
                        color: context.appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }

                  final item = list[index - 2];
                  return _ActivityCard(
                    item: item,
                    onTap: () => _openActivityDetail(context, item),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _PengumumanErrorState(
            message: _safeErrorMessage(err),
            onRetry: () =>
                ref.read(pengumumanProvider.notifier).fetchPengumuman(),
          ),
        ),
      ),
    );
  }
}

void _openActivityDetail(BuildContext context, Pengumuman item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => _ActivityDetailScreen(item: item)));
}

class _HeaderRow extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HeaderRow({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Eksplor Kegiatan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appBorder),
            boxShadow: context.appCardShadow,
          ),
          child: IconButton(
            tooltip: 'Muat ulang',
            onPressed: onRefresh,
            icon: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFF4B3FF2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Pengumuman item;
  final VoidCallback onTap;

  const _ActivityCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final publishedLabel = _publishedDateLabel(item.publishedAt);
    final organizerLabel = _organizerLabel(item);
    final imageUrl = _resolvedImageUrl(item.imageUrl);
    final isNew = _isRecent(item.publishedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder),
            boxShadow: context.appCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl == null)
                  SizedBox(
                    height: 214,
                    width: double.infinity,
                    child: _PosterPlaceholder(item: item),
                  )
                else
                  _ActivityImagePanel(
                    imageUrl: imageUrl,
                    placeholder: _PosterPlaceholder(item: item),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              organizerLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: context.appPrimary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          if (isNew)
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.appPrimarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'BARU',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF4B3FF2),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _descriptionText(item),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: context.appMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: context.appFaint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              publishedLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.appMuted,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: context.appPrimary,
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
      ),
    );
  }
}

class _ActivityDetailScreen extends StatelessWidget {
  final Pengumuman item;

  const _ActivityDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedImageUrl(item.imageUrl);
    final organizerLabel = _organizerLabel(item);
    final publishedLabel = _publishedDateLabel(item.publishedAt);
    final isNew = _isRecent(item.publishedAt);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                _BackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detail Kegiatan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.appText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl == null)
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: _PosterPlaceholder(item: item),
                      )
                    else
                      _ActivityImagePanel(
                        imageUrl: imageUrl,
                        placeholder: _PosterPlaceholder(item: item),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  organizerLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: context.appPrimary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              if (isNew)
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appPrimarySoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'BARU',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF4B3FF2),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 17,
                                color: context.appFaint,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  publishedLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.appMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Caption',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _descriptionText(item),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.appMuted,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B3FF2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: context.appText),
        ),
      ),
    );
  }
}

class _ActivityImagePanel extends StatefulWidget {
  final String imageUrl;
  final Widget placeholder;

  const _ActivityImagePanel({
    required this.imageUrl,
    required this.placeholder,
  });

  @override
  State<_ActivityImagePanel> createState() => _ActivityImagePanelState();
}

class _ActivityImagePanelState extends State<_ActivityImagePanel> {
  late Future<Uint8List?> _imageBytesFuture;
  bool _hasRetried = false;

  @override
  void initState() {
    super.initState();
    _imageBytesFuture = _loadImageBytes();
  }

  @override
  void didUpdateWidget(covariant _ActivityImagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasRetried = false;
      _imageBytesFuture = _loadImageBytes(forceRefresh: true);
    }
  }

  Future<Uint8List?> _loadImageBytes({bool forceRefresh = false}) {
    return LocalImageCache.getOrFetchBytes(
      widget.imageUrl,
      forceRefresh: forceRefresh,
    );
  }

  void _scheduleForcedRefresh() {
    if (_hasRetried) {
      return;
    }

    _hasRetried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytesFuture = _loadImageBytes(forceRefresh: true);
      });
    });
  }

  Widget _placeholderPanel({bool showLoader = false}) {
    return SizedBox(
      height: 214,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.placeholder,
          if (showLoader)
            const Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _imageBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholderPanel(showLoader: true);
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          if (!_hasRetried) {
            _scheduleForcedRefresh();
            return _placeholderPanel(showLoader: true);
          }

          return _placeholderPanel();
        }

        return ColoredBox(
          color: const Color(0xFF171327),
          child: Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return _placeholderPanel(showLoader: true);
            },
            errorBuilder: (_, _, _) {
              _scheduleForcedRefresh();
              return _placeholderPanel(showLoader: !_hasRetried);
            },
          ),
        );
      },
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  final Pengumuman item;

  const _PosterPlaceholder({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = _posterPalette(item);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -8,
            left: -28,
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -24,
            bottom: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                5,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 22,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? const Color(0xFFFCE94F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: index.isEven
                          ? const Color(0xFFFCE94F)
                          : Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
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

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF3B2ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: Row(
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 22,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? const Color(0xFFFCE94F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: index.isEven
                                ? const Color(0xFFFCE94F)
                                : Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'POLYLIFE CAMPUS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: context.appPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.appPrimarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'BARU',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF4B3FF2),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada kegiatan dipublikasikan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Feed ini terhubung ke broadcast/pengumuman Laravel. Saat konten masuk, poster, judul, dan ringkasan akan otomatis mengisi kartu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: context.appMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PengumumanErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PengumumanErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 58,
              color: Color(0xFF6C63FF),
            ),
            const SizedBox(height: 14),
            Text(
              'Gagal memuat kegiatan kampus',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B3FF2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _publishedDateLabel(String raw) {
  try {
    final parsed = DateTime.parse(raw).toLocal();
    return DateFormat('dd MMMM yyyy', 'id_ID').format(parsed);
  } catch (_) {
    return raw.trim().isEmpty ? 'Tanggal belum tersedia' : raw;
  }
}

String _safeErrorMessage(Object error) {
  final message = error.toString();
  final lower = message.toLowerCase();
  final looksInternal =
      lower.contains('exception') ||
      lower.contains('http://') ||
      lower.contains('https://') ||
      lower.contains('/api/') ||
      lower.contains('errno') ||
      lower.contains('failed host lookup');

  if (!looksInternal) {
    return message;
  }

  return 'Kamu sedang offline atau koneksi sedang bermasalah. Kegiatan kampus akan dimuat lagi saat jaringan tersedia.';
}

String _organizerLabel(Pengumuman item) {
  final creatorName = item.creator?['name']?.toString().trim();
  if (creatorName != null && creatorName.isNotEmpty) {
    return creatorName.toUpperCase();
  }

  return item.targetMode.toUpperCase();
}

String _descriptionText(Pengumuman item) {
  final body = item.body?.trim();
  if (body != null && body.isNotEmpty) {
    return body;
  }

  if (item.excerpt.trim().isNotEmpty) {
    return item.excerpt.trim();
  }

  return 'Informasi kegiatan kampus akan ditampilkan di sini ketika broadcast tersedia.';
}

bool _isRecent(String raw) {
  try {
    final publishedAt = DateTime.parse(raw).toLocal();
    return DateTime.now().difference(publishedAt).inDays <= 14;
  } catch (_) {
    return false;
  }
}

List<Color> _posterPalette(Pengumuman item) {
  final key = (item.targetMode + item.title).toLowerCase();

  if (key.contains('global')) {
    return const [Color(0xFF0B1023), Color(0xFF1F3C88)];
  }

  if (key.contains('admin') || key.contains('kampus')) {
    return const [Color(0xFF191919), Color(0xFF5A4B12)];
  }

  if (key.contains('organisasi') || key.contains('bem')) {
    return const [Color(0xFF14213D), Color(0xFF2563EB)];
  }

  return const [Color(0xFF121212), Color(0xFF4237DD)];
}

String? _resolvedImageUrl(String? rawPath) {
  return ApiConfig.resolveMediaUrl(rawPath);
}
