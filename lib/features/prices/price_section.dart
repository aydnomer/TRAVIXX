import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/price_service.dart';
import '../places/place_model.dart';

/// Mekan detayındaki "Fiyatlar" bölümü: ziyaretçilerin bildirdiği
/// fiyatların özeti ve "Fiyat bildir" düğmesi.
class PriceSection extends StatefulWidget {
  final Place place;
  const PriceSection({super.key, required this.place});

  @override
  State<PriceSection> createState() => _PriceSectionState();
}

class _PriceSectionState extends State<PriceSection> {
  List<PriceSummary> _summary = const [];
  List<PriceReport> _recent = const [];
  bool _loading = true;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PriceService.summary(widget.place.id),
      PriceService.recent(widget.place.id),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as List<PriceSummary>;
      _recent = results[1] as List<PriceReport>;
      _loading = false;
    });
  }

  Future<void> _openReport() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _snack(I18n.t('nl.loginRequired'));
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSheet(place: widget.place),
    );
    if (ok == true && mounted) {
      _snack(I18n.t('nl.thanks'));
      _load();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_summary.isEmpty)
            Text(I18n.t('nl.noPrices'),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary, height: 1.5))
          else
            ..._summary.map(_summaryRow),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.sell_outlined, size: 16),
                label: Text(I18n.t('nl.reportPrice')),
              ),
              const Spacer(),
              if (_recent.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _showRecent = !_showRecent),
                  child: Text(_showRecent
                      ? I18n.t('nl.hideReports')
                      : I18n.tp('nl.showReports',
                          {'n': '${_recent.length}'})),
                ),
            ],
          ),
          if (_showRecent)
            ..._recent.map((r) => _reportRow(r, mine: r.userId == me)),
          const SizedBox(height: 6),
          Text(I18n.t('nl.disclaimer'),
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _summaryRow(PriceSummary s) {
    final range = s.reports > 1 && s.low != s.high
        ? '  (${PriceService.format(s.low, s.currency)}–${PriceService.format(s.high, s.currency)})'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(itemEmoji(s.item), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itemLabel(s.item),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(
                  '${I18n.tp('nl.reports', {'n': '${s.reports}'})}'
                  '${s.lastSeen != null ? ' · ${_ago(s.lastSeen!)}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '~${PriceService.format(s.median, s.currency)}$range',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(PriceReport r, {required bool mine}) {
    final title = r.item == 'other' && (r.label?.isNotEmpty ?? false)
        ? r.label!
        : itemLabel(r.item);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(itemEmoji(r.item), style: const TextStyle(fontSize: 16)),
      title: Text('$title · ${PriceService.format(r.amount, r.currency)}'),
      subtitle: Text(
        [
          DateFormat.yMMMd(I18n.language.value).format(r.observedOn),
          if (r.note?.isNotEmpty ?? false) r.note!,
        ].join(' · '),
      ),
      trailing: mine
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: I18n.t('nl.delete'),
              onPressed: () async {
                if (await PriceService.delete(r.id)) _load();
              },
            )
          : null,
    );
  }

  String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return I18n.t('nl.today');
    return I18n.tp('nl.daysAgo', {'n': '$days'});
  }
}

/// Kalemin görünen adı.
String itemLabel(String item) => I18n.t('nl.item.$item');

String itemEmoji(String item) => const {
      'entry': '🎟️',
      'sunbed': '⛱️',
      'cocktail': '🍹',
      'beer': '🍺',
      'soft_drink': '🥤',
      'water': '💧',
      'coffee': '☕',
      'main_dish': '🍽️',
    }[item] ??
    '🏷️';

/// Mekan türüne göre önce gösterilecek kalem.
String defaultItemFor(Place p) {
  final sub = p.subcategory ?? '';
  if (sub == 'Beach Club' || p.category == 'Plaj') return 'sunbed';
  if (sub == 'Gece Kulübü') return 'entry';
  if (p.isNightlife) return 'cocktail';
  if (p.category == 'Müze' || p.category == 'Tarihi') return 'entry';
  return 'main_dish';
}

class _ReportSheet extends StatefulWidget {
  final Place place;
  const _ReportSheet({required this.place});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late String _item = defaultItemFor(widget.place);
  String _currency = 'TRY';
  final _amount = TextEditingController();
  final _label = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amount.text.trim().replaceAll(' ', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = I18n.t('nl.invalidAmount'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await PriceService.report(
      placeId: widget.place.id,
      item: _item,
      amount: amount,
      currency: _currency,
      label: _item == 'other' ? _label.text : null,
      note: _note.text,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = I18n.t(err == 'duplicate' ? 'nl.duplicate' : 'nl.failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(I18n.t('nl.reportPrice'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 4),
            Text(widget.place.name,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PriceService.items.map((i) {
                return ChoiceChip(
                  label: Text('${itemEmoji(i)} ${itemLabel(i)}'),
                  selected: _item == i,
                  onSelected: (_) => setState(() => _item = i),
                );
              }).toList(),
            ),
            if (_item == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _label,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: I18n.t('nl.itemName'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: I18n.t('nl.amount'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _currency,
                  items: PriceService.currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v ?? 'TRY'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: I18n.t('nl.note'),
                hintText: I18n.t('nl.noteHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(I18n.t('nl.send')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
