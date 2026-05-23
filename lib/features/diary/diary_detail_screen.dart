import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/database_service.dart';
import '../places/place_model.dart';
import 'diary_models.dart';
import 'diary_service.dart';

/// Bir defterin detayı: kapak + timeline + entry ekleme.
class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;
  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  TripDiary? _diary;
  List<DiaryEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      DiaryService.getDiary(widget.diaryId),
      DiaryService.getEntries(widget.diaryId),
    ]);
    if (!mounted) return;
    setState(() {
      _diary = results[0] as TripDiary?;
      _entries = results[1] as List<DiaryEntry>;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final added = await showModalBottomSheet<DiaryEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEntrySheet(diaryId: widget.diaryId),
    );
    if (added != null && mounted) _load();
  }

  Future<void> _deleteEntry(DiaryEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(I18n.t('diary.entryDelete')),
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
      await DiaryService.deleteEntry(e.id);
      if (mounted) _load();
    }
  }

  Color _hex(String? hex) {
    if (hex == null) return AppTheme.accentOrange;
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final d = _diary;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(I18n.t('diary.notFound'))),
      );
    }

    final color = _hex(d.coverColor);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        backgroundColor: AppTheme.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(I18n.t('diary.newEntry')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/diaries'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Opacity(
                        opacity: 0.2,
                        child: Text(d.emoji,
                            style: const TextStyle(fontSize: 200)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(d.emoji,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            d.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_entries.length} ${I18n.t('diary.entries')}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✏️', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        I18n.t('diary.noEntries'),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _EntryTile(
                    entry: _entries[i],
                    onDelete: () => _deleteEntry(_entries[i]),
                  ),
                  childCount: _entries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onDelete;
  const _EntryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy, EEEE', 'tr_TR');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                if (entry.placeEmoji != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      entry.placeEmoji!,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                if (entry.placeEmoji != null) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.placeName != null)
                        Text(
                          entry.placeName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      Text(
                        fmt.format(entry.entryDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.mood != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(entry.mood!,
                        style: const TextStyle(fontSize: 22)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (entry.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                entry.note,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          if (entry.photoUrl != null && entry.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13)),
              child: Image.network(
                entry.photoUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Yeni girdi ekleme bottom sheet
class _AddEntrySheet extends StatefulWidget {
  final String diaryId;
  const _AddEntrySheet({required this.diaryId});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _noteCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _mood;
  Place? _selectedPlace;
  List<Place> _places = const [];
  bool _placesLoading = false;
  bool _submitting = false;

  static const _moodOptions = ['😍', '😊', '🤩', '😎', '🥰', '🙏', '🌟'];

  @override
  void dispose() {
    _noteCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPlace() async {
    if (_places.isEmpty && !_placesLoading) {
      setState(() => _placesLoading = true);
      final list = await DatabaseService.getAllPlaces();
      if (!mounted) return;
      setState(() {
        _places = list;
        _placesLoading = false;
      });
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PlacePicker(places: _places),
    );
    if (picked != null) setState(() => _selectedPlace = picked);
  }

  Future<void> _submit() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final entry = await DiaryService.addEntry(
      diaryId: widget.diaryId,
      placeId: _selectedPlace?.id,
      entryDate: _date,
      note: _noteCtrl.text.trim(),
      photoUrl: _photoUrlCtrl.text.trim().isEmpty
          ? null
          : _photoUrlCtrl.text.trim(),
      mood: _mood,
    );
    if (!mounted) return;
    Navigator.pop(context, entry);
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
        child: SingleChildScrollView(
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
                I18n.t('diary.newEntry'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Mekan seçici
              OutlinedButton.icon(
                onPressed: _pickPlace,
                icon: const Icon(Icons.place, size: 16),
                label: Text(
                  _selectedPlace == null
                      ? I18n.t('diary.pickPlace')
                      : '${_selectedPlace!.emoji} ${_selectedPlace!.name}',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Tarih seçici
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (p != null) setState(() => _date = p);
                },
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(fmt.format(_date),
                    style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Mood seçici
              Wrap(
                spacing: 6,
                children: _moodOptions.map((m) {
                  final selected = m == _mood;
                  return GestureDetector(
                    onTap: () => setState(() => _mood = selected ? null : m),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accentOrange.withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accentOrange
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(m, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: I18n.t('diary.note'),
                  hintText: I18n.t('diary.noteHint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _photoUrlCtrl,
                decoration: InputDecoration(
                  labelText: I18n.t('diary.photoUrl'),
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.image, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                        : I18n.t('diary.saveEntry'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class _PlacePicker extends StatefulWidget {
  final List<Place> places;
  const _PlacePicker({required this.places});

  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.places.take(60).toList()
        : widget.places
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                p.nameEn.toLowerCase().contains(_query.toLowerCase()))
            .take(60)
            .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: I18n.t('search.hint'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return ListTile(
                      leading:
                          Text(p.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(p.name),
                      subtitle: Text(p.category,
                          style: const TextStyle(fontSize: 11)),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
