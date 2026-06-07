import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/reminder/models/reminder_target_option.dart';
import 'package:mobile_ver/features/reminder/providers/reminder_list_provider.dart';
import 'package:mobile_ver/features/reminder/providers/upcoming_reminder_provider.dart';

class ReminderCreateScreen extends ConsumerStatefulWidget {
  const ReminderCreateScreen({super.key});

  @override
  ConsumerState<ReminderCreateScreen> createState() =>
      _ReminderCreateScreenState();
}

class _ReminderCreateScreenState extends ConsumerState<ReminderCreateScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<ReminderTargetOption> _targets = const <ReminderTargetOption>[];
  String _selectedTargetKey = 'todolist';
  int? _selectedOptionId;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _active = true;

  ReminderTargetOption? get _selectedTarget {
    for (final target in _targets) {
      if (target.key == _selectedTargetKey) {
        return target;
      }
    }

    return _targets.isEmpty ? null : _targets.first;
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final targets = await ref
          .read(reminderListProvider.notifier)
          .loadOptions();

      final firstTarget = targets.isEmpty ? null : targets.first;

      setState(() {
        _targets = targets;
        _selectedTargetKey = firstTarget?.key ?? 'todolist';
        _selectedOptionId = firstTarget?.options.isEmpty == false
            ? firstTarget!.options.first.id
            : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat opsi reminder.';
      });
    }
  }

  void _selectTarget(String key) {
    ReminderTargetOption? target;
    for (final item in _targets) {
      if (item.key == key) {
        target = item;
        break;
      }
    }

    setState(() {
      _selectedTargetKey = key;
      _selectedOptionId = target?.options.isEmpty == false
          ? target!.options.first.id
          : null;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    final target = _selectedTarget;
    if (target == null) {
      setState(
        () => _errorMessage = 'Belum ada target reminder yang tersedia.',
      );
      return;
    }

    if (_selectedOptionId == null) {
      setState(() => _errorMessage = 'Pilih item yang ingin diingatkan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(reminderListProvider.notifier)
          .createReminder(
            target: target,
            targetId: _selectedOptionId!,
            scheduledAt: _scheduledAt,
            active: _active,
          );
      if (!success) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Gagal menyimpan reminder.';
        });
        return;
      }

      await ref.read(reminderListProvider.notifier).load();
      await ref
          .read(upcomingReminderProvider.notifier)
          .fetchReminder(showLoader: false, force: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder berhasil ditambahkan.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Gagal menyimpan reminder.';
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _selectedTarget;
    final selectedOptionId = _selectedOptionId;

    return Scaffold(
      backgroundColor: context.appBackground,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Tambah Reminder',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
      ),
      bottomNavigationBar: _isLoading
          ? null
          : _CreateReminderFooter(
              active: _active,
              isSubmitting: _isSubmitting,
              onChanged: (value) => setState(() => _active = value),
              onSubmit: _isSubmitting ? null : _submit,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOptions,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 176),
                children: [
                  const _CreateReminderHeroCard(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _CreateErrorBanner(message: _errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel(text: 'PILIH JENIS REMINDER'),
                        const SizedBox(height: 12),
                        if (_targets.isEmpty)
                          const _EmptyTargetPanel()
                        else
                          Column(
                            children: [
                              for (var i = 0; i < _targets.length; i++) ...[
                                _TargetSelectorCard(
                                  target: _targets[i],
                                  selected:
                                      _targets[i].key == _selectedTargetKey,
                                  onTap: () => _selectTarget(_targets[i].key),
                                ),
                                if (i != _targets.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SelectionHeader(
                          title: '${target?.label ?? 'Item'} terkait',
                          subtitle: _selectionSubtitle(target),
                        ),
                        const SizedBox(height: 12),
                        if (target == null || target.options.isEmpty)
                          const _EmptyTargetPanel(
                            title: 'Belum ada data untuk target ini.',
                            subtitle:
                                'Tambahkan dulu item pada menu terkait agar reminder bisa dihubungkan.',
                          )
                        else
                          DropdownButtonFormField<int>(
                            key: ValueKey('${target.key}:$selectedOptionId'),
                            initialValue: selectedOptionId,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280),
                            ),
                            decoration: _inputDecoration(),
                            items: [
                              for (final option in target.options)
                                DropdownMenuItem<int>(
                                  value: option.id,
                                  child: Text(
                                    option.label,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF221D33),
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _selectedOptionId = value),
                          ),
                        const SizedBox(height: 18),
                        const _SectionLabel(text: 'WAKTU REMINDER'),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAE8FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event_outlined,
                                    color: Color(0xFF4E44F2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy, hh:mm a',
                                          'id_ID',
                                        ).format(_scheduledAt),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF221D33),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ketuk untuk mengubah jadwal pengingat',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7C829C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TargetSelectorCard extends StatelessWidget {
  final ReminderTargetOption target;
  final bool selected;
  final VoidCallback onTap;

  const _TargetSelectorCard({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFC7C2FF)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x124E44F2),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFFEAE8FF) : Colors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF4E44F2)
                        : const Color(0xFF9CA3AF),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF4E44F2),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            target.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF221D33),
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAE8FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Dipilih',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4E44F2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      target.helper,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: const Color(0xFF7C829C),
                      ),
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

class _CreateReminderHeroCard extends StatelessWidget {
  const _CreateReminderHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E5F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4D42F2), Color(0xFF5D52F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENGINGAT BARU',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF5A50E8),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tautkan reminder ke to-do, tugas, jadwal, atau kegiatan supaya PolyLife bisa mengingatkan tepat waktu.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: const Color(0xFF6F7690),
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

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E5F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SelectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF221D33),
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: const Color(0xFF7C829C),
            ),
          ),
        ],
      ],
    );
  }
}

class _CreateReminderFooter extends StatelessWidget {
  final bool active;
  final bool isSubmitting;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onSubmit;

  const _CreateReminderFooter({
    required this.active,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          elevation: 18,
          shadowColor: const Color(0x220F172A),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Aktif',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF221D33),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            active
                                ? 'Reminder akan dikirim sesuai jadwal.'
                                : 'Reminder disimpan dalam keadaan nonaktif.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C829C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: active,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF6B5BFF),
                      onChanged: onChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4E44F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Simpan Reminder',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

class _EmptyTargetPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyTargetPanel({
    this.title = 'Belum ada target reminder.',
    this.subtitle =
        'Tambahkan item terkait lebih dulu agar reminder bisa dihubungkan.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF221D33),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: const Color(0xFF7C829C),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateErrorBanner extends StatelessWidget {
  final String message;

  const _CreateErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFDA4AF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFBE123C),
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFC7C2FF), width: 1.4),
    ),
  );
}

String _selectionSubtitle(ReminderTargetOption? target) {
  if (target == null) {
    return '';
  }

  return 'Pilih item ${target.label.toLowerCase()} yang ingin dihubungkan ke reminder ini.';
}
