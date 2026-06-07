import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/keuangan/utils/category_icon_resolver.dart';

void main() {
  group('resolveKeuanganCategoryIcon', () {
    test('uses income-specific icons before expense matching', () {
      expect(
        resolveKeuanganCategoryIcon(
          kategori: 'Gaji bulanan',
          jenis: 'pemasukan',
        ),
        Icons.payments_outlined,
      );
      expect(
        resolveKeuanganCategoryIcon(
          kategori: 'Bonus lomba',
          jenis: 'pemasukan',
        ),
        Icons.card_giftcard_outlined,
      );
    });

    test('maps common expense categories', () {
      expect(
        resolveKeuanganCategoryIcon(kategori: 'Makan siang'),
        Icons.restaurant_outlined,
      );
      expect(
        resolveKeuanganCategoryIcon(kategori: 'Bensin motor'),
        Icons.directions_car_outlined,
      );
      expect(
        resolveKeuanganCategoryIcon(kategori: 'Buku kuliah'),
        Icons.menu_book_outlined,
      );
    });

    test('returns fallback icon for empty or unknown category', () {
      expect(
        resolveKeuanganCategoryIcon(kategori: '', jenis: 'pemasukan'),
        Icons.south_west_rounded,
      );
      expect(
        resolveKeuanganCategoryIcon(kategori: 'Tidak dikenal'),
        Icons.receipt_long_outlined,
      );
    });
  });
}
