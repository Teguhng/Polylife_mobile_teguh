import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

class JadwalNextAgendaCard extends StatelessWidget {
  final JadwalItem? item;
  final VoidCallback onOpenAgenda;

  const JadwalNextAgendaCard({
    super.key,
    required this.item,
    required this.onOpenAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: item == null
          ? const _EmptyCard()
          : _FilledCard(item: item!, onOpenAgenda: onOpenAgenda),
    );
  }
}

class _FilledCard extends StatelessWidget {
  final JadwalItem item;
  final VoidCallback onOpenAgenda;

  const _FilledCard({required this.item, required this.onOpenAgenda});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startsIn = item.startAt.difference(now);
    final startDate = DateFormat('EEE, dd MMM', 'id_ID').format(item.startAt);
    final startTime = DateFormat('HH:mm').format(item.startAt);
    final endTime = DateFormat('HH:mm').format(item.endAt);

    String countdown;
    if (startsIn.inMinutes <= 0) {
      countdown = 'Sedang berlangsung';
    } else if (startsIn.inHours < 1) {
      countdown = 'Mulai ${startsIn.inMinutes} menit lagi';
    } else {
      countdown = 'Mulai ${startsIn.inHours} jam lagi';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGENDA BERIKUTNYA',
          style: TextStyle(
            color: context.appPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$startDate • $startTime - $endTime',
          style: TextStyle(
            color: context.appMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item.location.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(item.location.trim(), style: TextStyle(color: context.appMuted)),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.appPrimarySoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                countdown,
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onOpenAgenda,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Lihat'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGENDA BERIKUTNYA',
          style: TextStyle(
            color: context.appPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Belum ada agenda terdekat.',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tambahkan jadwal kuliah atau ujian agar ringkasan harian muncul.',
          style: TextStyle(color: context.appMuted),
        ),
      ],
    );
  }
}
