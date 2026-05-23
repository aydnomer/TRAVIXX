import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import 'diary_models.dart';
import 'diary_service.dart';

/// Kullanıcının tüm gezi defterleri.
class DiariesScreen extends StatefulWidget {
  const DiariesScreen({super.key});

  @override
  State<DiariesScreen> createState() => _DiariesScreenState();
}

class _DiariesScreenState extends State<DiariesScreen> {
  List<TripDiary> _diaries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DiaryService.getMyDiaries();
    if (!mounted) return;
    setState(() {
      _diaries = list;
      _loading = false;
    });
  }

  Future<void> _createDiary() async {
    final created = await showModalBottomSheet<TripDiary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateDiarySheet(),
    );
    if (created != null && mounted) {
      _load();
    }
  }

  Future<void> _confirmDelete(TripDiary d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(I18n.t('diary.delete')),
        content: Text(I18n.t('diary.deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(I18n.t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(I18n.t('diary.delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DiaryService.deleteDiary(d.id);
      if (mounted) _load();
    }
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.accentOrange;
    final clean = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.accentOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(I18n.t('diary.title')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _createDiary,
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(I18n.t('diary.newDiary')),
            ),
      body: user == null
          ? _buildLoginRequired()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _diaries.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _diaries.length,
                        itemBuilder: (context, i) {
                          final d = _diaries[i];
                          return _DiaryCard(
                            diary: d,
                            color: _hexColor(d.coverColor),
                            onTap: () => context.push('/diary/${d.id}'),
                            onDelete: () => _confirmDelete(d),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            I18n.t('diary.loginRequired'),
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.login),
            label: Text(I18n.t('nav.login')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              I18n.t('diary.empty'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              I18n.t('diary.emptyDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final TripDiary diary;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiaryCard({
    required this.diary,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'tr_TR');
    final dateRange = [
      if (diary.startDate != null) fmt.format(diary.startDate!),
      if (diary.endDate != null) '→ ${fmt.format(diary.endDate!)}',
    ].join(' ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Renkli üst başlık
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Opacity(
                        opacity: 0.2,
                        child: Text(diary.emoji,
                            style: const TextStyle(fontSize: 120)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Text(diary.emoji,
                              style: const TextStyle(fontSize: 28)),
                          const Spacer(),
                          if (diary.isPublic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                I18n.t('diary.public'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Alt bilgi
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diary.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_note,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${diary.entryCount} ${I18n.t('diary.entries')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (dateRange.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.date_range,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateRange,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

/// Yeni defter oluşturma alt sayfası
class _CreateDiarySheet extends StatefulWidget {
  const _CreateDiarySheet();

  @override
  State<_CreateDiarySheet> createState() => _CreateDiarySheetState();
}

class _CreateDiarySheetState extends State<_CreateDiarySheet> {
  final _titleCtrl = TextEditingController();
  String _emoji = '📖';
  String _color = '#F97316';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPublic = false;
  bool _submitting = false;

  static const _emojiOptions = ['📖', '✈️', '🏖️', '🏛️', '🌄', '🗺️', '🎒', '📸'];
  static const _colorOptions = [
    '#F97316', '#EF4444', '#EC4899', '#8B5CF6',
    '#3B82F6', '#06B6D4', '#10B981', '#F59E0B',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final created = await DiaryService.createDiary(
      title: _titleCtrl.text.trim(),
      emoji: _emoji,
      coverColor: _color,
      startDate: _startDate,
      endDate: _endDate,
      isPublic: _isPublic,
    );
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  Color _hex(String h) {
    return Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy', 'tr_TR');
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              I18n.t('diary.newDiary'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: I18n.t('diary.titleLabel'),
                hintText: I18n.t('diary.titleHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Emoji seçici
            Wrap(
              spacing: 6,
              children: _emojiOptions.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentOrange.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.accentOrange : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Renk seçici
            Wrap(
              spacing: 6,
              children: _colorOptions.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hex(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Tarihler
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      _startDate != null
                          ? fmt.format(_startDate!)
                          : I18n.t('diary.startDate'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      _endDate != null
                          ? fmt.format(_endDate!)
                          : I18n.t('diary.endDate'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: Text(I18n.t('diary.makePublic')),
              subtitle: Text(
                I18n.t('diary.makePublicDesc'),
                style: const TextStyle(fontSize: 11),
              ),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppTheme.accentOrange,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _submitting
                      ? I18n.t('common.loading')
                      : I18n.t('diary.create'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
