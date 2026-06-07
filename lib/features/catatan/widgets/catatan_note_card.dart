import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/features/catatan/models/catatan_model.dart';

class CatatanNoteCard extends StatefulWidget {
  final Catatan item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CatatanNoteCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CatatanNoteCard> createState() => _CatatanNoteCardState();
}

class _CatatanNoteCardState extends State<CatatanNoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(widget.item.tanggalAsDate);
    final content = widget.item.listPreview.isEmpty
        ? widget.item.showPreview
              ? '(Tanpa isi)'
              : 'Preview disembunyikan'
        : widget.item.listPreview;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _expanded
                      ? Icons.fullscreen_exit_rounded
                      : Icons.open_in_full_rounded,
                  size: 18,
                  color: const Color(0xFFA5B4FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.judul,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 31 / 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF334155), height: 1.35),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
