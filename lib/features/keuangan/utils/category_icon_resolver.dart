import 'package:flutter/material.dart';

IconData resolveKeuanganCategoryIcon({
  required String kategori,
  String? jenis,
  IconData emptyFallback = Icons.category_outlined,
}) {
  final normalized = _normalizeCategory(kategori);
  final normalizedJenis = (jenis ?? '').trim().toLowerCase();

  if (normalized.isEmpty) {
    if (normalizedJenis == 'pemasukan') {
      return Icons.south_west_rounded;
    }
    return emptyFallback;
  }

  // Prioritize income matching first so icons for pemasukan stay distinct
  // even if the category text overlaps with common expense words.
  if (normalizedJenis == 'pemasukan') {
    if (_containsRoot(normalized, [
      'gaji',
      'upah',
      'uang saku',
      'thr',
      'tunjangan',
      'honor',
      'insentif',
    ])) {
      return Icons.payments_outlined;
    }

    if (_containsRoot(normalized, [
      'freelance',
      'proyek',
      'jasa',
      'konsultasi',
      'project',
    ])) {
      return Icons.work_outline;
    }

    if (_containsRoot(normalized, ['beasiswa', 'hibah', 'bantuan'])) {
      return Icons.workspace_premium_outlined;
    }

    if (_containsRoot(normalized, ['bonus', 'hadiah', 'lomba', 'doorprize'])) {
      return Icons.card_giftcard_outlined;
    }

    if (_containsRoot(normalized, [
      'investasi',
      'dividen',
      'bunga',
      'saham',
      'reksa',
      'deposito',
      'crypto',
      'emas',
    ])) {
      return Icons.trending_up_outlined;
    }

    if (_containsRoot(normalized, ['tabungan', 'cair tabungan'])) {
      return Icons.savings_outlined;
    }

    if (_containsRoot(normalized, [
      'penjualan',
      'jual',
      'omzet',
      'dagang',
      'reseller',
    ])) {
      return Icons.storefront_outlined;
    }

    if (_containsRoot(normalized, ['komisi', 'affiliate', 'referral'])) {
      return Icons.point_of_sale_outlined;
    }

    if (_containsRoot(normalized, ['royalti', 'lisensi', 'sewa aset'])) {
      return Icons.monetization_on_outlined;
    }

    if (_containsRoot(normalized, [
      'refund',
      'reimburse',
      'retur',
      'cashback',
    ])) {
      return Icons.replay_outlined;
    }

    if (_containsRoot(normalized, ['sponsor', 'sponsorship', 'donasi masuk'])) {
      return Icons.volunteer_activism_outlined;
    }

    return Icons.south_west_rounded;
  }

  if (_containsRoot(normalized, [
    'transport',
    'angkut',
    'ojek',
    'bensin',
    'bbm',
    'parkir',
    'tol',
    'bus',
    'kereta',
  ])) {
    return Icons.directions_car_outlined;
  }

  if (_containsRoot(normalized, [
    'makan',
    'kuliner',
    'kopi',
    'coffee',
    'jajan',
    'snack',
    'resto',
    'food',
  ])) {
    return Icons.restaurant_outlined;
  }

  if (_containsRoot(normalized, [
    'buku',
    'kursus',
    'kelas',
    'kuliah',
    'pendidik',
    'alat tulis',
    'atk',
  ])) {
    return Icons.menu_book_outlined;
  }

  if (_containsRoot(normalized, [
    'belanja',
    'grocery',
    'sembako',
    'market',
    'supermarket',
    'minimarket',
  ])) {
    return Icons.shopping_bag_outlined;
  }

  if (_containsRoot(normalized, [
    'kost',
    'sewa',
    'kontrak',
    'rumah',
    'apartemen',
    'hunian',
  ])) {
    return Icons.home_work_outlined;
  }

  if (_containsRoot(normalized, [
    'listrik',
    'air',
    'pln',
    'internet',
    'wifi',
    'pulsa',
    'tagihan',
    'utilitas',
  ])) {
    return Icons.receipt_outlined;
  }

  if (_containsRoot(normalized, [
    'kesehat',
    'obat',
    'klinik',
    'dokter',
    'rumah sakit',
    'rs',
    'medical',
  ])) {
    return Icons.health_and_safety_outlined;
  }

  if (_containsRoot(normalized, [
    'hiburan',
    'movie',
    'film',
    'gaming',
    'game',
    'langganan',
    'subscription',
    'musik',
  ])) {
    return Icons.movie_outlined;
  }

  if (_containsRoot(normalized, ['donasi', 'zakat', 'sedekah', 'charity'])) {
    return Icons.volunteer_activism_outlined;
  }

  if (_containsRoot(normalized, [
    'cicilan',
    'asuransi',
    'pajak',
    'pinjaman',
    'kredit',
    'utang',
  ])) {
    return Icons.request_quote_outlined;
  }

  if (normalizedJenis == 'pemasukan') {
    return Icons.south_west_rounded;
  }

  return Icons.receipt_long_outlined;
}

String _normalizeCategory(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsRoot(String source, List<String> roots) {
  for (final root in roots) {
    if (source.contains(root)) {
      return true;
    }
  }
  return false;
}
