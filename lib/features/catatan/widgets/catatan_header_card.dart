import 'package:flutter/material.dart';

class CatatanHeaderCard extends StatelessWidget {
  final int trashCount;
  final VoidCallback onCreate;
  final VoidCallback onOpenTrash;

  const CatatanHeaderCard({
    super.key,
    required this.trashCount,
    required this.onCreate,
    required this.onOpenTrash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SIMPAN IDE, RINGKASAN, DLL',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catatan Pribadi',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 34 / 2,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(width: 6),
              Text(
                'Semua catatan terenkripsi',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Baru'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: onOpenTrash,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Sampah ($trashCount)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
