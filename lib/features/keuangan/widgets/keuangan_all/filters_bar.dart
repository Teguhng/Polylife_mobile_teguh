import 'package:flutter/material.dart';

class FiltersBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String jenisFilter;
  final ValueChanged<String> onJenisChanged;
  final String monthFilterLabel;
  final VoidCallback onMonthFilterPressed;

  const FiltersBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.jenisFilter,
    required this.onJenisChanged,
    required this.monthFilterLabel,
    required this.onMonthFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Cari kategori/deskripsi',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildJenisChip('semua', 'Semua'),
                      const SizedBox(width: 6),
                      _buildJenisChip('pemasukan', 'Pemasukan'),
                      const SizedBox(width: 6),
                      _buildJenisChip('pengeluaran', 'Pengeluaran'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onMonthFilterPressed,
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text(
                  monthFilterLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJenisChip(String value, String label) {
    final selected = jenisFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onJenisChanged(value),
      selectedColor: const Color(0xFFEEF2FF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
      ),
      backgroundColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
